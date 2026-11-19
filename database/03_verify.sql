USE libman;
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- Counts for the physical schema.
SELECT 'tblMember' AS tableName, COUNT(*) AS rowCount FROM tblMember
UNION ALL
SELECT 'tblReader' AS tableName, COUNT(*) AS rowCount FROM tblReader
UNION ALL
SELECT 'tblEmployee' AS tableName, COUNT(*) AS rowCount FROM tblEmployee
UNION ALL
SELECT 'tblReaderCard' AS tableName, COUNT(*) AS rowCount FROM tblReaderCard
UNION ALL
SELECT 'tblDocument' AS tableName, COUNT(*) AS rowCount FROM tblDocument
UNION ALL
SELECT 'tblSupplier' AS tableName, COUNT(*) AS rowCount FROM tblSupplier
UNION ALL
SELECT 'tblImport' AS tableName, COUNT(*) AS rowCount FROM tblImport
UNION ALL
SELECT 'tblImportDetail' AS tableName, COUNT(*) AS rowCount FROM tblImportDetail
UNION ALL
SELECT 'tblItem' AS tableName, COUNT(*) AS rowCount FROM tblItem
UNION ALL
SELECT 'tblLoan' AS tableName, COUNT(*) AS rowCount FROM tblLoan
UNION ALL
SELECT 'tblLoanDetail' AS tableName, COUNT(*) AS rowCount FROM tblLoanDetail
UNION ALL
SELECT 'tblReturn' AS tableName, COUNT(*) AS rowCount FROM tblReturn
UNION ALL
SELECT 'tblReturnDetail' AS tableName, COUNT(*) AS rowCount FROM tblReturnDetail
UNION ALL
SELECT 'tblFine' AS tableName, COUNT(*) AS rowCount FROM tblFine
UNION ALL
SELECT 'tblFinePayment' AS tableName, COUNT(*) AS rowCount FROM tblFinePayment
UNION ALL
SELECT 'tblSupplierPayment' AS tableName, COUNT(*) AS rowCount FROM tblSupplierPayment;

SELECT COUNT(*) AS foreignKeys FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE();
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS indexColumns
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE() AND NON_UNIQUE = 0
GROUP BY TABLE_NAME, INDEX_NAME ORDER BY TABLE_NAME, INDEX_NAME;

SELECT m.id, m.fullName, e.employeeCode, r.readerCode
FROM tblMember m JOIN tblReader r ON r.memberId = m.id
JOIN tblEmployee e ON e.memberId = m.id;

SELECT d.documentCode, d.title, COUNT(i.id) AS totalItems,
       SUM(CASE WHEN i.itemStatus = 'AVAILABLE' THEN 1 ELSE 0 END) AS availableItems,
       d.borrowable + 0 AS borrowable
FROM tblDocument d
LEFT JOIN tblImportDetail s ON s.documentId = d.id
LEFT JOIN tblItem i ON i.importDetailId = s.id
GROUP BY d.id, d.documentCode, d.title, d.borrowable ORDER BY d.documentCode;

SELECT l.loanNumber, COUNT(ld.id) AS items, COUNT(DISTINCT ld.dueDate) AS distinctDueDates
FROM tblLoan l JOIN tblLoanDetail ld ON ld.loanId = l.id
GROUP BY l.id HAVING COUNT(DISTINCT ld.dueDate) > 1 ORDER BY l.loanNumber;

-- Kỳ hồi quy 01–12/11/2026. Tính trọn ngày theo giờ Việt Nam.
SET @periodStart = '2026-10-31 17:00:00', @periodEnd = '2026-11-12 17:00:00';
SELECT r.readerCode, m.fullName, COUNT(*) AS borrowCount
FROM tblLoan l JOIN tblReader r ON r.memberId = l.readerId JOIN tblMember m ON m.id = r.memberId
WHERE l.checkoutDateTime >= @periodStart AND l.checkoutDateTime < @periodEnd
GROUP BY r.memberId, r.readerCode, m.fullName ORDER BY borrowCount DESC, r.memberId;

SELECT r.readerCode, l.loanNumber, TIMESTAMPADD(HOUR, 7, l.checkoutDateTime) AS checkoutVietnam
FROM tblLoan l JOIN tblReader r ON r.memberId = l.readerId
WHERE r.readerCode = 'R001' AND l.checkoutDateTime >= @periodStart AND l.checkoutDateTime < @periodEnd
ORDER BY l.checkoutDateTime DESC, l.id;

SELECT l.loanNumber, r.readerCode, member.fullName AS readerName, staff.fullName AS staffName,
       i.itemCode, d.documentCode, d.title, ld.dueDate
FROM tblLoan l JOIN tblReader r ON r.memberId = l.readerId
JOIN tblMember member ON member.id = r.memberId JOIN tblMember staff ON staff.id = l.processedById
JOIN tblLoanDetail ld ON ld.loanId = l.id JOIN tblItem i ON i.id = ld.itemId
JOIN tblImportDetail origin ON origin.id = i.importDetailId JOIN tblDocument d ON d.id = origin.documentId
WHERE l.loanNumber = 'PM-B001' ORDER BY ld.id;

-- List the offending slips for diagnosis. Valid data produces no rows.
SELECT l.id, l.loanNumber, l.readerId, l.checkoutDateTime
FROM tblLoan l
WHERE NOT EXISTS (SELECT 1 FROM tblLoanDetail ld WHERE ld.loanId = l.id)
ORDER BY l.id;

-- Each of the following checks should return zero violations.
SELECT 'import_quantity' AS checkName, COUNT(*) AS violations FROM (
    SELECT s.id FROM tblImportDetail s LEFT JOIN tblItem i ON i.importDetailId = s.id
    GROUP BY s.id, s.quantity HAVING COUNT(i.id) <> s.quantity
) mismatches
UNION ALL
SELECT 'orphan_item_or_document', COUNT(*) FROM tblItem i
LEFT JOIN tblImportDetail s ON s.id = i.importDetailId LEFT JOIN tblDocument d ON d.id = s.documentId
WHERE d.id IS NULL
UNION ALL
SELECT 'orphan_loan_detail', COUNT(*) FROM tblLoanDetail ld
LEFT JOIN tblLoan l ON l.id = ld.loanId LEFT JOIN tblItem i ON i.id = ld.itemId
WHERE l.id IS NULL OR i.id IS NULL
UNION ALL
SELECT 'loan_without_details', COUNT(*) FROM tblLoan l
LEFT JOIN tblLoanDetail ld ON ld.loanId = l.id WHERE ld.id IS NULL
UNION ALL
SELECT 'return_before_checkout', COUNT(*) FROM tblReturnDetail rd
JOIN tblReturn r ON r.id = rd.returnId JOIN tblLoanDetail ld ON ld.id = rd.loanDetailId
JOIN tblLoan l ON l.id = ld.loanId WHERE r.returnDateTime < l.checkoutDateTime
UNION ALL
SELECT 'return_spanning_loans', COUNT(*) FROM (
    SELECT rd.returnId FROM tblReturnDetail rd JOIN tblLoanDetail ld ON ld.id = rd.loanDetailId
    GROUP BY rd.returnId HAVING COUNT(DISTINCT ld.loanId) > 1
) mismatches
UNION ALL
SELECT 'loan_before_import_or_invalid_due_date', COUNT(*) FROM tblLoanDetail ld
JOIN tblLoan l ON l.id = ld.loanId JOIN tblItem i ON i.id = ld.itemId
JOIN tblImportDetail s ON s.id = i.importDetailId JOIN tblImport im ON im.id = s.importId
WHERE l.checkoutDateTime < im.confirmationDateTime
   OR ld.dueDate < DATE(TIMESTAMPADD(HOUR, 7, l.checkoutDateTime))
UNION ALL
SELECT 'overlapping_loans', COUNT(*) FROM tblLoanDetail a
JOIN tblLoan la ON la.id = a.loanId JOIN tblLoanDetail b ON b.itemId = a.itemId AND b.id > a.id
JOIN tblLoan lb ON lb.id = b.loanId
LEFT JOIN tblReturnDetail ra ON ra.loanDetailId = a.id LEFT JOIN tblReturn ta ON ta.id = ra.returnId
LEFT JOIN tblReturnDetail rb ON rb.loanDetailId = b.id LEFT JOIN tblReturn tb ON tb.id = rb.returnId
WHERE (ta.id IS NULL OR lb.checkoutDateTime < ta.returnDateTime)
  AND (tb.id IS NULL OR la.checkoutDateTime < tb.returnDateTime)
UNION ALL
SELECT 'open_loan_item_status', COUNT(*) FROM tblItem i
WHERE (i.itemStatus = 'BORROWED') <> EXISTS (
    SELECT 1 FROM tblLoanDetail ld LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id
    WHERE ld.itemId = i.id AND rd.id IS NULL
)
UNION ALL
SELECT 'fine_payment_amount', COUNT(*) FROM tblFinePayment p JOIN tblFine f ON f.id = p.fineId
WHERE p.amount <> f.amount
UNION ALL
SELECT 'supplier_payment_amount', COUNT(*) FROM tblSupplierPayment p
WHERE NOT (p.amount <=> (SELECT SUM(quantity * unitPrice) FROM tblImportDetail WHERE importId = p.importId));

-- Kiểm tra toàn vẹn. Mỗi kết quả violations phải bằng 0.
SET @snapshotExclusive = '2026-11-20 17:00:00';
SET SESSION group_concat_max_len = 32768;

-- All relationships in this schema are single-column foreign keys.
SELECT COUNT(*) INTO @foreignKeyCount
FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE();
SELECT GROUP_CONCAT(
    CONCAT('SELECT ', QUOTE(CONCAT(k.TABLE_NAME, '.', k.COLUMN_NAME)), ' AS checkName, COUNT(*) AS violations',
           ' FROM `', k.TABLE_NAME, '` c LEFT JOIN `', k.REFERENCED_TABLE_NAME, '` p',
           ' ON p.`', k.REFERENCED_COLUMN_NAME, '` = c.`', k.COLUMN_NAME, '`',
           ' WHERE c.`', k.COLUMN_NAME, '` IS NOT NULL AND p.`', k.REFERENCED_COLUMN_NAME, '` IS NULL')
    ORDER BY k.TABLE_NAME, k.COLUMN_NAME SEPARATOR ' UNION ALL ')
INTO @foreignKeyChecks
FROM information_schema.KEY_COLUMN_USAGE k
WHERE k.CONSTRAINT_SCHEMA = DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL;
SET @foreignKeyChecks = COALESCE(@foreignKeyChecks, 'SELECT ''missing_foreign_keys'' AS checkName, 1 AS violations');
PREPARE verifyForeignKeys FROM @foreignKeyChecks;
EXECUTE verifyForeignKeys;
DEALLOCATE PREPARE verifyForeignKeys;

-- Reconcile the SQL catalog with the bibliographic manifest from catalog_sources.csv.
-- For a month-only release, the manifest stores its last day as a conservative lower bound for acquisition.
CREATE TEMPORARY TABLE verifiedCatalog (
    documentCode VARCHAR(64) NOT NULL PRIMARY KEY,
    releaseDate DATE NOT NULL,
    metadataHash CHAR(64) NOT NULL
);
INSERT INTO verifiedCatalog (documentCode, releaseDate, metadataHash) VALUES
    ('DOC-01', '2019-03-31', 'a3df0750c4a215de04a806c17b3c88c3e9819124f022f9e667eac6aec487952d'),
    ('DOC-02', '2019-12-19', 'b86c960c931a394dd5688bba2f062ecbb3642049effff69d1b6c28e992a6de2b'),
    ('DOC-03', '2022-04-05', '929bbcaf7237d6988c8761ef08353c73fa7d4b79564f731dd549d08b190a762b'),
    ('DOC-04', '2016-11-18', '23f04e7b675acfacefbbb41915aa9c2ab537831080bbed7850730aadf8470495'),
    ('DOC-05', '2008-07-01', '18c0b6b294ac4d024048ba93952ccdb95f3c1d726f3ad3e5d2d7698c82551617'),
    ('DOC-06', '1980-05-27', '7a4b8b72183481f53ee9238ad41d4efbfdb7307e50f3987b19e1d3883146007d'),
    ('DOC-07', '2024-03-05', 'f8b9b7d8448dffea492989ddfb070e7e04200562b448cfa798b0599100054db2'),
    ('DOC-08', '2006-07-27', '4eea20d3754b6531126b3b5601b078c961f22f0f46dcef553ba5e9852d3cc771'),
    ('DOC-09', '2021-06-15', 'b5c6ad5875184a47206242032aaaa94aeb4ed0b1a2f907e311792f7be0519218'),
    ('DOC-10', '2019-01-29', '0e6bad8231bdd71489adb69fabb7b2d8b0966d125c1f65f92791f0729fd2c091'),
    ('DOC-11', '2018-11-13', 'f697c03121d8843a59740b3650b9f14692d3ada5f4a6bb7f240dff692ee80114'),
    ('DOC-12', '2016-01-22', '2e4b1e1c832557a6236d15b67c20d7197b8e5097437fb45edf30e385befdb043'),
    ('DOC-13', '2009-12-03', '61ffd3a5633a482d222188c41c77dbfb39d67918305a336c0eab31bb9e30a14f'),
    ('DOC-14', '2010-06-24', 'c4583c206ed9028483d334467d009013af455dab1727ca8198cbb0ace961140b'),
    ('DOC-15', '2008-12-11', 'ce93d90f00c2c140d935aa8da2c8538a72c9aa03d2fbce6b895a569f11210e48'),
    ('DOC-16', '2024-11-13', 'bcad7b94ad0fcd02e0eb12facbac0caab8fc642120db28014fd6a1e4bc385619'),
    ('DOC-17', '2025-03-05', 'ee08ed68ca7732ca1a01b7b176eb834d49a04ecbb122ff7f2e616578481cc0c3'),
    ('DOC-18', '2023-11-29', 'ec14eaca42381015a6c2c5840410038101a98acbf09c4afd7d89a7edf86bd536'),
    ('DOC-19', '2025-01-24', '193f58777a1da16dc4af9e97557c980b85c3b1afa54b79b9791f301970927fef'),
    ('DOC-20', '2016-09-19', 'a82f4405609ff4a21f2cd657c8870f9f5cd2122ce775e9200c529f1483b12b49'),
    ('DOC-21', '2016-10-06', '6181f6baae0700e160d59617f914a7aa3b71abbf2134afcc6822322cc87799c7'),
    ('DOC-22', '2016-09-29', '147ebca97ac5469f3c257bdec4bd9871dddf4203443b3325775e196e5ce2c408'),
    ('DOC-23', '2022-07-13', 'e4a2b93d12414e80884047e56c17d86208029c9e41cbd4579b83cb4d40f89b96'),
    ('DOC-24', '2020-03-26', '1b6569a01baab1492bb172557ca15add3cf515466228c3cd92a873fd2df517dd'),
    ('DOC-25', '2025-03-05', 'e21e9671987e1bff8b8cf08fee65f2b338c14c96c700385f5e14a3bd9e1ad399'),
    ('DOC-26', '2021-12-21', 'c148bb0d1484a287c048e9e178b4019625dc43715766946229b3020df3c7b69a'),
    ('DOC-27', '2016-03-30', '85808c6d57b334c0efd8a81e178492ae16dbd2c02c76528aae9add8363a332d8'),
    ('DOC-28', '2016-03-30', '9de2e28238093474f9499dea1790bde69dd15b2b144193fcd7df29bee5b1ff76'),
    ('DOC-29', '2016-03-30', '4ed035a6b0f2f9094ca5bd2c8e12188e5c748c2c8527ca45b514ba1c11c876df'),
    ('DOC-30', '2021-12-21', '18f88f60d6f8bbde81d08128521593d16350a412b5c66c2303c4d209db1006f4'),
    ('DOC-31', '2023-03-22', '1800b69a51ccea576a02c7e7706b365c0bb16057c89d86862483be43bfbd34a6'),
    ('DOC-32', '2020-05-06', '11abd7651fca0b7f0e1d62616a28bc576d678496cc5dcc07c99879e8f166d317'),
    ('DOC-33', '2021-12-21', '65dd9dc208c739caddc363ee95209f7eb8a76c30d53a6d150360500886941b9b'),
    ('DOC-34', '2023-12-13', 'a3632a44132c5f79c11f711e5c45305513414b6c9598cad66338ac9ab30aeeab'),
    ('DOC-35', '2020-03-27', 'aebbcef5dcef9ff6673fc34bff707ae671c6becf2b8429460c47c59d3c925dd1'),
    ('DOC-36', '2018-09-24', 'e89adad317f1b0ab3f0fa4d997d45572b59faa549fa12cc42110d2a02f9c5456'),
    ('DOC-37', '2026-06-24', '89a9cfe36f6b7b5cd0ef89521d6bb198b96757b5f18c6a37859748125f798ec0'),
    ('DOC-38', '2020-01-16', '14fd3e2207811a65b836c661a800b79275849d9e4de5817e658b91d57e95a590'),
    ('DOC-39', '2026-04-22', 'f6c417fbbc48f9b6d3607dbb605b6e16293f79aec49fb045d9749c7b1ff8e7a8'),
    ('DOC-40', '2021-02-22', '6752ccf2a31cb86ca43fd436ad94f58d4431e5af2df4f1002829c421f5b2cd5e'),
    ('DOC-41', '2023-12-13', 'dd534159c3157274c90d3ab819ff74c8ba39ec71829aa715f583a94119967572'),
    ('DOC-42', '2019-06-05', '5ea31d2b5ea0c5e402f72b4334726d4471e4f8df015335aefb61a98507179c21'),
    ('DOC-43', '2019-04-11', '6e3768b985cfa05a6c075f13969ad02ea4861840c3526a3483fe4cb62d6ceacd'),
    ('DOC-44', '2019-02-14', '0f020ca81d80f263ab0f0644ddff2c125e6821d5b65c935b9dfdb810569ee010'),
    ('DOC-45', '2022-12-14', '7792129f366dbcbaed2fbd550789f5922dc2b14c97d74db5b2a5322fa0bf83ca'),
    ('DOC-46', '2026-06-24', '02d82df600ab9fd6324e1c71c216d53c1ef4febe78fab08c27f26b54bbd42245'),
    ('DOC-47', '2022-12-14', '58998a49e3b992abf06b82afbb690742737c5f3105e06fd4017bd743502fb46e'),
    ('DOC-48', '2019-03-20', '223157174e8acba33326da44139e4bac66693836b240bc01b3f03374d54dfc83'),
    ('DOC-49', '2023-01-25', '4729c74cf2bf39bf0ae281324916d39a8d8c364c0b105f6964ca87d0e57d8e98'),
    ('DOC-50', '2022-12-14', 'aaf1946fcf8a8081a986beae95da1b0f950d7f8c17dc954fa0d821b431ce7409'),
    ('DOC-51', '2021-12-21', 'c462a5eb9365e58a9c8a0cc61e757784f27e4fb0c99aa5cf3bd78fbef5181da7'),
    ('DOC-52', '2022-06-15', 'a769a89894864d779047cb977760f692dc8d277f2fee953a928e94cbcf018de4'),
    ('DOC-53', '2022-05-18', 'a69449952ccd49c01bfc15ccb0ced3c54ff11c4222f54b9973dac25abd4d5ee5'),
    ('DOC-54', '2021-06-03', 'ec6eadc016e74a2c0b8ac11e80918f5f0840d89c47758bf573b8c239b1fb0370'),
    ('DOC-55', '2019-12-16', 'f35c94dffd6b283680daf2be56f3d48748de4b30b10a64987d3c6660077d625e'),
    ('DOC-56', '2020-03-17', '3e3dd81debf5d408f987b6767d9e1285a7ac5cf8ecd15320000749f544a6deec'),
    ('DOC-57', '2020-02-20', 'ca891b39675e7fa42723aef8f403d35a4268af7eb9996d2e3fa2e053136be033'),
    ('DOC-58', '2012-06-29', '80b1b183b66f8da2f15357e5d96891325689173157039270569e406213f71406'),
    ('DOC-59', '2025-09-10', '3d72c7f4529bf6d94df73ff2edad1a7dc4c9582673b40d6ea885d70e87619848'),
    ('DOC-60', '2007-10-12', 'bfa80e8085a522bc055798bd6a428c7e3ce7cb9669956c5b1ef4cf259c583675'),
    ('DOC-61', '2019-12-19', 'c7b732311def04fd38eb4bcaa34f9c9daa8ba62927781d46b31168eee25a0e14'),
    ('DOC-62', '2007-04-26', '9f4f9c909f5ad32fbb160b9b09226a6605f10467c08fd7dfb2f467655fc12fc5'),
    ('DOC-63', '2013-03-29', 'bfbd213de197de9c0433ed7b0f652d1389274c66c6d1cebb7891de58f44c0938'),
    ('DOC-64', '2020-12-15', 'e18fe0865a265311a3bb331bf094ce48153252cad4a96ce61a07f23a5e71ac41'),
    ('DOC-65', '2016-06-29', '14ae84bdec27372374453f7dd4578deeca78d67d949c97078f89bcb3c3b86cc5'),
    ('DOC-66', '2008-08-21', '4746c86b42af417d5bcbdcd806461e8ff4112716658afca40f765e61976f86d4'),
    ('DOC-67', '2011-11-03', '3e603ff37ef136a5a488bcf0974683323451db10d11f352779d793a9d43b89f2'),
    ('DOC-68', '2018-05-04', '7f4231e5e70459158cbf700d2b0823a6482fa87db00f506f41443809afeb23bb'),
    ('DOC-69', '2016-10-15', 'bf4c9cd4ceddbb9d1d9fb451be9f485e13fabe7dc37542ef497f4e8ef4e7a04f'),
    ('DOC-70', '2007-08-14', 'ef984059649c288b45c58522bb7ddfbaecc8d8f447d273e1d1f304c39096cd9c'),
    ('DOC-71', '2023-07-25', '14d7149546367fa3ca13f0e0dfdf4aa1b6a4e071edaf8278ff1ced58723b2472'),
    ('DOC-72', '2022-09-25', 'b6f335a2966ba46e5f7d7de76c86a0c07c331123beb6dbcbb8cb910837aed728'),
    ('DOC-73', '2024-04-27', 'b52881b926b3eee94eec5d4a2416de0324be5d28f41571049bdab9ff5156a0b1'),
    ('DOC-74', '2023-10-04', '5c597b1c4d7ec3f188185a19500558cd9809126befc59c36149445016390f6fd'),
    ('DOC-75', '2018-08-18', 'fe856c6a393c365333edb578d48a670b06e40f6f985f301eb4bd1670a9aa5935'),
    ('DOC-76', '2016-11-04', 'c103779b3f0a2998632831d84276a9204aaf56e351f9681e256af3ad6c56bbba'),
    ('DOC-77', '2014-10-09', '8dd2767c24659fd3ae568f2c0ee89a0ab15c994f329b7f6d4b1320e03b0b3826'),
    ('DOC-78', '2024-06-28', '36b38d5d39616f4b446117e2f1360eb4f53646c722c8edd880e13be09cf23e24'),
    ('DOC-79', '2016-08-23', '9bf337096e25f2153d672f7fc42c6bc64fc588a8fd71be9ec035572da374db09'),
    ('DOC-80', '2024-06-26', '01517a41c2c7c47fe9657da489a78fe693ced0b79a67122c98c193c509706306'),
    ('DOC-81', '2018-10-17', '2276b335f5d5f9612432e1c70cbf5ae8b460a03bbf9b97db7051f7479dcbe7cf'),
    ('DOC-82', '2023-04-02', '62ca101dcfa08eb0950c2d14228b711431f0188fe2dc9d683a8fb4db3b9dd397'),
    ('DOC-83', '2024-11-03', 'b21086bc9cd5deb898d5488f6e9d5a9e9dcf66c9986735dd69046dee4c153b54'),
    ('DOC-84', '2018-12-23', '66b00187992328856b49dff6b8847dd9c38420386a96e50e17b42b70317ff273'),
    ('DOC-85', '2014-11-21', '37cc58ee38df436cdca97bef2466633d03d9f4873314dd5f51e949862045869c'),
    ('DOC-86', '2019-01-12', '3b2fb642a20d566395bf156cea9d111d4356722952bea55725fe08aa499a9a4f'),
    ('DOC-87', '2010-07-09', '99fa4a427e15387fb8b6d3d4801d06a8548ca8a3941c6a7e8e09b3b1df0d6f2c'),
    ('DOC-88', '2022-09-22', 'ec9283ccbe8754724a2b06a28c94ed5b98b259e463ca288d0fc1310fb7a697e3'),
    ('DOC-89', '2022-04-20', '9708c4eb97552dc503622a7f35529529f62e3a055b91dc629a7405c770d3180b'),
    ('DOC-90', '2023-11-02', 'a3aa71b4c0bef72188d7506ad38b27cd153a901aa6ca2df6c775ab87b43f99d3'),
    ('DOC-91', '2023-06-23', 'edb70a32af259bc90f4af956c2525dafdd73dd1cf1e24059d38c4846bf45da85');

WITH latestItemHistory AS (
    SELECT ld.itemId, rd.id AS returnDetailId, rd.`condition` AS returnCondition,
           ROW_NUMBER() OVER (PARTITION BY ld.itemId ORDER BY l.checkoutDateTime DESC, ld.id DESC) AS recency
    FROM tblLoanDetail ld JOIN tblLoan l ON l.id = ld.loanId
    LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id
), codes AS (
    SELECT 'member' AS kind, username AS code FROM tblMember
    UNION ALL SELECT 'reader', readerCode FROM tblReader
    UNION ALL SELECT 'employee', employeeCode FROM tblEmployee
    UNION ALL SELECT 'card', cardNumber FROM tblReaderCard
    UNION ALL SELECT 'document', documentCode FROM tblDocument
    UNION ALL SELECT 'supplier', supplierCode FROM tblSupplier
    UNION ALL SELECT 'import', importNumber FROM tblImport
    UNION ALL SELECT 'item', itemCode FROM tblItem
    UNION ALL SELECT 'loan', loanNumber FROM tblLoan
    UNION ALL SELECT 'return', returnNumber FROM tblReturn
    UNION ALL SELECT 'fine_payment', receiptNumber FROM tblFinePayment
    UNION ALL SELECT 'supplier_payment', paymentReference FROM tblSupplierPayment WHERE paymentReference IS NOT NULL
), processors AS (
    SELECT processedById FROM tblImport
    UNION ALL SELECT processedById FROM tblLoan
    UNION ALL SELECT processedById FROM tblReturn
    UNION ALL SELECT assessedById FROM tblFine
    UNION ALL SELECT processedById FROM tblFinePayment
    UNION ALL SELECT processedById FROM tblSupplierPayment
), transactions AS (
    SELECT confirmationDateTime AS occurredAt FROM tblImport
    UNION ALL SELECT checkoutDateTime FROM tblLoan
    UNION ALL SELECT returnDateTime FROM tblReturn
    UNION ALL SELECT paymentDateTime FROM tblFinePayment
    UNION ALL SELECT paymentDateTime FROM tblSupplierPayment
), digits AS (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
), identifiers AS (
    SELECT documentCode, REPLACE(UPPER(isbnOrIssn), '-', '') AS code
    FROM tblDocument WHERE isbnOrIssn IS NOT NULL
), identifierChecksums AS (
    SELECT i.documentCode, CHAR_LENGTH(i.code) AS digitCount, SUM(
        (CASE SUBSTRING(i.code, d.n, 1) WHEN 'X' THEN 10 ELSE CAST(SUBSTRING(i.code, d.n, 1) AS UNSIGNED) END)
        * (CASE CHAR_LENGTH(i.code) WHEN 13 THEN IF(MOD(d.n, 2) = 1, 1, 3) ELSE CHAR_LENGTH(i.code) - d.n + 1 END)
    ) AS weightedSum
    FROM identifiers i JOIN digits d ON d.n <= CHAR_LENGTH(i.code)
    WHERE REGEXP_LIKE(i.code, '^(97[89][0-9]{10}|[0-9]{9}[0-9X]|[0-9]{7}[0-9X])$', 'c')
    GROUP BY i.documentCode, i.code
)
SELECT 'table_count' AS checkName, ABS(CAST(COUNT(*) AS SIGNED) - 16) AS violations
FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
UNION ALL SELECT 'foreign_key_count', ABS(CAST(@foreignKeyCount AS SIGNED) - 21)
UNION ALL SELECT 'duplicate_business_code', COUNT(*) FROM (
    SELECT kind, code FROM codes GROUP BY kind, code HAVING COUNT(*) > 1
) duplicated
UNION ALL SELECT 'duplicate_returned_loan_detail', COUNT(*) FROM (
    SELECT loanDetailId FROM tblReturnDetail GROUP BY loanDetailId HAVING COUNT(*) > 1
) duplicated
UNION ALL SELECT 'empty_import', COUNT(*) FROM tblImport t
    WHERE NOT EXISTS (SELECT 1 FROM tblImportDetail id WHERE id.importId = t.id)
UNION ALL SELECT 'empty_return', COUNT(*) FROM tblReturn t
    WHERE NOT EXISTS (SELECT 1 FROM tblReturnDetail rd WHERE rd.returnId = t.id)
UNION ALL SELECT 'return_not_strictly_after_checkout', COUNT(*)
    FROM tblReturnDetail rd JOIN tblReturn r ON r.id = rd.returnId
    JOIN tblLoanDetail ld ON ld.id = rd.loanDetailId JOIN tblLoan l ON l.id = ld.loanId
    WHERE r.returnDateTime <= l.checkoutDateTime
UNION ALL SELECT 'current_item_status', COUNT(*)
    FROM tblItem i LEFT JOIN latestItemHistory h ON h.itemId = i.id AND h.recency = 1
    WHERE i.itemStatus <> CASE
        WHEN h.itemId IS NULL THEN 'AVAILABLE'
        WHEN h.returnDetailId IS NULL THEN 'BORROWED'
        WHEN h.returnCondition = 'NORMAL' THEN 'AVAILABLE'
        ELSE h.returnCondition END
UNION ALL SELECT 'loan_after_irrecoverable_return', COUNT(*)
    FROM tblReturnDetail rd JOIN tblReturn r ON r.id = rd.returnId
    JOIN tblLoanDetail prior ON prior.id = rd.loanDetailId
    JOIN tblLoanDetail subsequent ON subsequent.itemId = prior.itemId
    JOIN tblLoan l ON l.id = subsequent.loanId
    WHERE rd.`condition` IN ('DAMAGED', 'LOST') AND l.checkoutDateTime >= r.returnDateTime
UNION ALL SELECT 'invalid_role_mapping', COUNT(*)
    FROM tblMember m LEFT JOIN tblReader r ON r.memberId = m.id LEFT JOIN tblEmployee e ON e.memberId = m.id
    WHERE NOT ((m.role = 'READER' AND r.memberId IS NOT NULL AND e.memberId IS NULL)
            OR (m.role IN ('STAFF', 'MANAGER') AND r.memberId IS NULL AND e.memberId IS NOT NULL))
UNION ALL SELECT 'processor_is_not_active_staff', COUNT(*)
    FROM processors p LEFT JOIN tblEmployee e ON e.memberId = p.processedById
    LEFT JOIN tblMember m ON m.id = e.memberId
    WHERE m.id IS NULL OR m.role <> 'STAFF' OR m.status <> 'ACTIVE'
UNION ALL SELECT 'reader_status_mismatch', COUNT(*)
    FROM tblReader r JOIN tblMember m ON m.id = r.memberId WHERE r.readerStatus <> m.status
UNION ALL SELECT 'overlapping_card_validity', COUNT(*)
    FROM tblReaderCard a JOIN tblReaderCard b ON a.readerId = b.readerId AND a.issueSequence < b.issueSequence
    WHERE b.issueDate <= a.expiryDate OR b.issueDate <= a.issueDate
UNION ALL SELECT 'active_card_snapshot_mismatch', COUNT(*)
    FROM tblReaderCard
    WHERE (cardStatus = 'ACTIVE') <> (DATE('2026-11-20') BETWEEN issueDate AND expiryDate)
UNION ALL SELECT 'loan_without_valid_card', COUNT(*)
    FROM tblLoan l JOIN tblReader r ON r.memberId = l.readerId
    WHERE r.readerStatus <> 'ACTIVE' OR NOT EXISTS (
        SELECT 1 FROM tblReaderCard c WHERE c.readerId = l.readerId
        AND c.cardStatus IN ('ACTIVE', 'EXPIRED')
        AND DATE(TIMESTAMPADD(HOUR, 7, l.checkoutDateTime)) BETWEEN c.issueDate AND c.expiryDate
    )
UNION ALL SELECT 'future_transaction', COUNT(*) FROM transactions WHERE occurredAt >= @snapshotExclusive
UNION ALL SELECT 'future_card_issue', COUNT(*) FROM tblReaderCard WHERE issueDate > '2026-11-20'
UNION ALL SELECT 'reading_room_only_loan', COUNT(*)
    FROM tblLoanDetail ld JOIN tblItem i ON i.id = ld.itemId
    JOIN tblImportDetail incoming ON incoming.id = i.importDetailId JOIN tblDocument d ON d.id = incoming.documentId
    WHERE d.borrowable = b'0'
UNION ALL SELECT 'invalid_identifier_format', COUNT(*)
    FROM identifiers WHERE NOT REGEXP_LIKE(code, '^(97[89][0-9]{10}|[0-9]{9}[0-9X]|[0-9]{7}[0-9X])$', 'c')
UNION ALL SELECT 'identifier_checksum', COUNT(*) FROM identifierChecksums
    WHERE MOD(weightedSum, IF(digitCount = 13, 10, 11)) <> 0
UNION ALL SELECT 'identifier_kind_mismatch', COUNT(*) FROM tblDocument
    WHERE isbnOrIssn IS NOT NULL AND (documentType = 'MAGAZINE') <> REGEXP_LIKE(isbnOrIssn, '^[0-9]{4}-[0-9]{3}[0-9X]$', 'c')
UNION ALL SELECT 'unsupported_code', COUNT(*) FROM (
    SELECT documentType FROM tblDocument WHERE documentType NOT IN ('BOOK', 'TEXTBOOK', 'MAGAZINE', 'OTHER')
    UNION ALL SELECT itemStatus FROM tblItem WHERE itemStatus NOT IN ('AVAILABLE', 'BORROWED', 'DAMAGED', 'LOST')
    UNION ALL SELECT `condition` FROM tblReturnDetail WHERE `condition` NOT IN ('NORMAL', 'DAMAGED', 'LOST')
    UNION ALL SELECT cardStatus FROM tblReaderCard WHERE cardStatus NOT IN ('ACTIVE', 'EXPIRED')
    UNION ALL SELECT paymentMethod FROM tblFinePayment WHERE paymentMethod NOT IN ('CASH', 'TRANSFER')
    UNION ALL SELECT paymentMethod FROM tblSupplierPayment WHERE paymentMethod <> 'TRANSFER'
) unsupported
UNION ALL SELECT 'fine_reason_or_amount', COUNT(*)
    FROM tblFine f JOIN tblLoanDetail ld ON ld.id = f.loanDetailId
    LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id LEFT JOIN tblReturn r ON r.id = rd.returnId
    WHERE f.reason <> 'OVERDUE' OR r.id IS NULL OR DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)) <= ld.dueDate
       OR f.amount <> 2000 * LEAST(30, DATEDIFF(DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)), ld.dueDate))
UNION ALL SELECT 'fine_payment_before_assessment_event', COUNT(*)
    FROM tblFinePayment p JOIN tblFine f ON f.id = p.fineId
    LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = f.loanDetailId LEFT JOIN tblReturn r ON r.id = rd.returnId
    WHERE r.id IS NULL OR p.paymentDateTime < r.returnDateTime
UNION ALL SELECT 'supplier_payment_before_acquisition', COUNT(*)
    FROM tblSupplierPayment p JOIN tblImport im ON im.id = p.importId
    WHERE p.paymentDateTime < im.confirmationDateTime;

SELECT 'catalog_missing_or_metadata_mismatch' AS checkName, COUNT(*) AS violations
FROM tblDocument d LEFT JOIN verifiedCatalog v ON v.documentCode = d.documentCode
WHERE v.documentCode IS NULL OR v.metadataHash <> SHA2(CONCAT(
    title, CHAR(31), COALESCE(author, ''), CHAR(31), publisher, CHAR(31), publicationYear, CHAR(31),
    COALESCE(isbnOrIssn, ''), CHAR(31), COALESCE(edition, ''), CHAR(31), documentType, CHAR(31), subjectClassification), 256)
   OR d.publisher IS NULL OR d.publicationYear IS NULL OR d.subjectClassification IS NULL;

SELECT 'verified_catalog_entry_without_document' AS checkName, COUNT(*) AS violations
FROM verifiedCatalog v LEFT JOIN tblDocument d ON d.documentCode = v.documentCode WHERE d.id IS NULL;

SELECT 'acquired_before_print_release' AS checkName, COUNT(*) AS violations
FROM tblImportDetail id JOIN tblImport im ON im.id = id.importId JOIN tblDocument d ON d.id = id.documentId
JOIN verifiedCatalog v ON v.documentCode = d.documentCode
WHERE DATE(TIMESTAMPADD(HOUR, 7, im.confirmationDateTime)) < v.releaseDate;

DROP TEMPORARY TABLE verifiedCatalog;


-- MD1: tìm kiếm, chính sách mượn và số bản tài liệu.
-- All passes should be 1. For negative search/report cases, zero matches proves the case.
WITH stock AS (
    SELECT d.id, d.documentCode, d.title, d.author, d.isbnOrIssn, d.documentType, d.publicationYear,
           d.borrowable, COUNT(i.id) AS total,
           SUM(IF(i.itemStatus = 'AVAILABLE', 1, 0)) AS available,
           SUM(IF(i.itemStatus = 'BORROWED', 1, 0)) AS borrowed,
           SUM(IF(i.itemStatus = 'DAMAGED', 1, 0)) AS damaged,
           SUM(IF(i.itemStatus = 'LOST', 1, 0)) AS lost,
           SUM(IF(i.itemStatus = 'AVAILABLE' AND i.location LIKE 'Kho %', 1, 0)) AS stockroomAvailable
    FROM tblDocument d
    LEFT JOIN tblImportDetail incoming ON incoming.documentId = d.id
    LEFT JOIN tblItem i ON i.importDetailId = incoming.id
    GROUP BY d.id
), cases AS (
    SELECT 'M1-01' AS scenario, COUNT(*) AS actual, 1 AS minimum, 1 AS maximum
    FROM stock WHERE documentCode = 'DOC-01' AND title LIKE '%Database System Concepts%'
    UNION ALL SELECT 'M1-02', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-01' AND author LIKE '%Silberschatz%'
    UNION ALL SELECT 'M1-03', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-05'
    UNION ALL SELECT 'M1-04', COUNT(*), 2, 2 FROM stock WHERE isbnOrIssn IN ('9780078022159', '0018-9219')
    UNION ALL SELECT 'M1-05', COUNT(*), 1, 1 FROM stock WHERE documentType = 'MAGAZINE' AND documentCode = 'DOC-07'
    UNION ALL SELECT 'M1-06', COUNT(*), 1, 1 FROM stock WHERE publicationYear = 2022 AND documentCode = 'DOC-03'
    UNION ALL SELECT 'M1-07', COUNT(*), 1, 1 FROM stock
        WHERE title LIKE '%Algorithms%' AND documentType = 'TEXTBOOK' AND publicationYear = 2022 AND documentCode = 'DOC-03'
    UNION ALL SELECT 'M1-08', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-05' AND total = 1
    UNION ALL SELECT 'M1-09', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-01' AND total = 6
    UNION ALL SELECT 'M1-10', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-06' AND total = 0
    UNION ALL SELECT 'M1-11', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-08' AND total = 3 AND available = 3
    UNION ALL SELECT 'M1-12', COUNT(*), 1, 1 FROM stock
        WHERE documentCode = 'DOC-01' AND borrowed = 1 AND available = 3 AND damaged = 1 AND lost = 1
    UNION ALL SELECT 'M1-13', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-03' AND total = 4 AND borrowed = 4
    UNION ALL SELECT 'M1-14', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-04' AND damaged = 1
    UNION ALL SELECT 'M1-15', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-04' AND lost = 1
    UNION ALL SELECT 'M1-16', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-02' AND borrowable = b'0' AND available = 3
    UNION ALL SELECT 'M1-17', COUNT(*), 1, 1 FROM stock WHERE documentCode = 'DOC-01' AND borrowable = b'1' AND stockroomAvailable = 1
    UNION ALL SELECT 'M1-18', COUNT(*), 2, 1000 FROM stock WHERE title LIKE '%Database%'
    UNION ALL SELECT 'M1-19', COUNT(*), 0, 0 FROM stock
        WHERE CONCAT_WS(' | ', title, author, documentCode, isbnOrIssn) LIKE '%libmanzz-nothing-778%'
)
SELECT scenario, actual, actual BETWEEN minimum AND maximum AS pass FROM cases ORDER BY scenario;

-- MD2: ca hồi quy kỳ 01–12/11/2026.
WITH reportLoans AS (
    SELECT l.id, l.loanNumber, l.checkoutDateTime, l.readerId, r.readerCode
    FROM tblLoan l JOIN tblReader r ON r.memberId = l.readerId
    WHERE l.checkoutDateTime >= @periodStart AND l.checkoutDateTime < @periodEnd
), reportReaders AS (
    SELECT readerId, readerCode, COUNT(*) AS slips
    FROM reportLoans GROUP BY readerId, readerCode
), loanState AS (
    SELECT l.id, l.loanNumber, COUNT(ld.id) AS copies, COUNT(rd.id) AS returned,
           COUNT(DISTINCT ld.dueDate) AS dueDates,
           SUM(IF(DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)) < ld.dueDate, 1, 0)) AS early,
           SUM(IF(DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)) = ld.dueDate, 1, 0)) AS onTime,
           SUM(IF(DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)) > ld.dueDate, 1, 0)) AS late,
           SUM(IF(r.returnDateTime >= @periodEnd, 1, 0)) AS returnedAfterPeriod
    FROM reportLoans l JOIN tblLoanDetail ld ON ld.loanId = l.id
    LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id LEFT JOIN tblReturn r ON r.id = rd.returnId
    GROUP BY l.id, l.loanNumber
), loanFines AS (
    SELECT l.loanNumber, f.id AS fineId, p.fineId AS paidFineId
    FROM reportLoans l JOIN tblLoanDetail ld ON ld.loanId = l.id JOIN tblFine f ON f.loanDetailId = ld.id
    LEFT JOIN tblFinePayment p ON p.fineId = f.id
), cases AS (
    SELECT 'M2-01' AS scenario, COUNT(*) AS actual, 1 AS expected FROM tblReader r
        WHERE r.readerCode = 'R090' AND NOT EXISTS (SELECT 1 FROM tblLoan l WHERE l.readerId = r.memberId)
    UNION ALL SELECT 'M2-02', COUNT(*), 1 FROM reportReaders WHERE readerCode = 'R002' AND slips = 1
    UNION ALL SELECT 'M2-03', COUNT(*), 1 FROM reportReaders WHERE readerCode = 'R001' AND slips = 3
    UNION ALL SELECT 'M2-04', COUNT(*), 2 FROM reportReaders WHERE readerCode IN ('R002', 'R003') AND slips = 1
    UNION ALL SELECT 'M2-05', COUNT(*), 6 FROM reportLoans
    UNION ALL SELECT 'M2-06', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B001' AND copies = 2
    UNION ALL SELECT 'M2-07', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B001' AND dueDates = 2
    UNION ALL SELECT 'M2-08', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B004' AND returned = 0 AND copies = 2
    UNION ALL SELECT 'M2-09', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B001' AND returned = 1 AND copies = 2
    UNION ALL SELECT 'M2-10', COUNT(*), 1 FROM loanState
        WHERE loanNumber = 'PM-B002' AND returned = copies AND early = 1 AND onTime = 1
    UNION ALL SELECT 'M2-11', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B003' AND late = 1
    UNION ALL SELECT 'M2-12', COUNT(*), 1 FROM loanState WHERE loanNumber = 'PM-B001' AND returnedAfterPeriod = 1
    UNION ALL SELECT 'M2-13', COUNT(*), 1 FROM loanFines WHERE loanNumber = 'PM-B003'
    UNION ALL SELECT 'M2-14', COUNT(*), 1 FROM loanFines WHERE loanNumber = 'PM-B003' AND paidFineId IS NULL
    UNION ALL SELECT 'M2-15', COUNT(*), 1 FROM loanFines WHERE loanNumber = 'PM-B001' AND paidFineId = fineId
    UNION ALL SELECT 'M2-16', COUNT(*), 0 FROM tblLoan
        WHERE checkoutDateTime >= '2024-12-31 17:00:00' AND checkoutDateTime < '2025-01-31 17:00:00'
    UNION ALL SELECT 'M2-17', COUNT(*), 1 FROM reportLoans
        WHERE loanNumber = 'PM-B001' AND checkoutDateTime = @periodStart
    UNION ALL SELECT 'M2-18', COUNT(*), 1 FROM reportLoans
        WHERE loanNumber = 'PM-B004' AND checkoutDateTime = TIMESTAMPADD(SECOND, -1, @periodEnd)
    UNION ALL SELECT 'M2-19', COUNT(*), 2 FROM tblLoan l
        WHERE (loanNumber = 'PM-B005' AND checkoutDateTime = @periodEnd)
           OR (loanNumber = 'PM-B006' AND checkoutDateTime = TIMESTAMPADD(SECOND, -1, @periodStart))
    UNION ALL SELECT 'M2-20', COUNT(*), 1 FROM reportLoans
        WHERE loanNumber = 'PM-B001' AND DATE(checkoutDateTime) = '2026-10-31'
              AND DATE(TIMESTAMPADD(HOUR, 7, checkoutDateTime)) = '2026-11-01'
    UNION ALL SELECT 'M2-21', COUNT(*), 2
        FROM reportLoans l JOIN tblLoanDetail ld ON ld.loanId = l.id JOIN tblItem i ON i.id = ld.itemId
        JOIN tblImportDetail incoming ON incoming.id = i.importDetailId JOIN tblDocument d ON d.id = incoming.documentId
        WHERE l.loanNumber = 'PM-B002' AND d.title <> '' AND ld.dueDate = '2026-11-10'
)
SELECT scenario, actual, actual = expected AS pass FROM cases ORDER BY scenario;

-- MD2: ca demo phiếu PM-B103 trong kỳ 01–15/11/2026.
WITH demoPeriod AS (
    SELECT id, readerId, loanNumber FROM tblLoan
    WHERE checkoutDateTime >= '2026-10-31 17:00:00' AND checkoutDateTime < '2026-11-15 17:00:00'
), demoSlip AS (
    SELECT i.itemCode, d.documentCode, i.itemStatus, ld.dueDate,
           DATE(TIMESTAMPADD(HOUR, 7, r.returnDateTime)) AS returnedOn
    FROM demoPeriod p JOIN tblLoanDetail ld ON ld.loanId = p.id
    JOIN tblItem i ON i.id = ld.itemId
    JOIN tblImportDetail incoming ON incoming.id = i.importDetailId
    JOIN tblDocument d ON d.id = incoming.documentId
    LEFT JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id
    LEFT JOIN tblReturn r ON r.id = rd.returnId
    WHERE p.loanNumber = 'PM-B103' AND p.readerId = 1
), cases AS (
    SELECT 'DEMO-01' AS scenario, COUNT(*) AS actual, 8 AS expected FROM demoPeriod
    UNION ALL SELECT 'DEMO-02', COUNT(DISTINCT readerId), 5 FROM demoPeriod
    UNION ALL SELECT 'DEMO-03', COUNT(*), 4 FROM demoPeriod WHERE readerId = 1
    UNION ALL SELECT 'DEMO-04', COUNT(*), 4 FROM demoSlip
    UNION ALL SELECT 'DEMO-05', COUNT(*), 4 FROM demoSlip WHERE
        (itemCode = 'IT-023' AND returnedOn = '2026-11-16' AND returnedOn < dueDate)
        OR (itemCode = 'IT-002' AND documentCode = 'DOC-01' AND itemStatus = 'BORROWED'
            AND returnedOn IS NULL AND dueDate < '2026-11-20')
        OR (itemCode = 'IT-025' AND returnedOn = '2026-11-19' AND returnedOn > dueDate)
        OR (itemCode = 'IT-178' AND returnedOn IS NULL AND dueDate > '2026-11-20')
    UNION ALL SELECT 'DEMO-06', COUNT(*), 3 FROM tblMember WHERE status = 'ACTIVE'
        AND ((username = 'reader001' AND role = 'READER')
            OR (username = 'librarystaff001' AND role = 'STAFF')
            OR (username = 'manager001' AND role = 'MANAGER'))
        AND password LIKE '{PBKDF2-SHA256}600000$%'
)
SELECT scenario, actual, actual = expected AS pass FROM cases ORDER BY scenario;

SELECT DATE_FORMAT(TIMESTAMPADD(HOUR, 7, checkoutDateTime), '%Y-%m') AS vietnamMonth, COUNT(*) AS slips
FROM tblLoan GROUP BY vietnamMonth ORDER BY vietnamMonth;

SELECT itemStatus, COUNT(*) AS copies FROM tblItem GROUP BY itemStatus ORDER BY itemStatus;
SELECT subjectClassification, COUNT(*) AS publications FROM tblDocument
GROUP BY subjectClassification ORDER BY publications DESC, subjectClassification;
