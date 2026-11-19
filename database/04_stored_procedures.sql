-- Apply after 01_schema.sql. Re-running this file replaces the procedures.
USE libman;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_find_active_account$$
CREATE PROCEDURE sp_find_active_account(IN p_username LONGTEXT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT id, username, password, role, status, fullName, address, email, phoneNumber
    FROM tblMember
    WHERE username = p_username AND status = 'ACTIVE' AND role IN ('READER', 'STAFF', 'MANAGER');
END$$

DROP PROCEDURE IF EXISTS sp_search_documents$$
CREATE PROCEDURE sp_search_documents(
    IN p_keyword LONGTEXT,
    IN p_field LONGTEXT,
    IN p_pattern LONGTEXT,
    IN p_type LONGTEXT,
    IN p_year INT
)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT d.id, d.documentCode, d.title, d.author, d.publicationYear, d.documentType, d.borrowable
    FROM tblDocument d
    WHERE (p_keyword = '' OR
           (CASE CAST(p_field AS BINARY)
               WHEN 'author' THEN d.author
               WHEN 'code' THEN d.documentCode
               WHEN 'isbn' THEN d.isbnOrIssn
               WHEN 'all' THEN CONCAT_WS(' | ', d.title, d.author, d.documentCode, d.isbnOrIssn)
               ELSE d.title
           END) COLLATE utf8mb4_0900_as_ci LIKE p_pattern ESCAPE '!')
      AND (p_type = '' OR d.documentType = p_type)
      AND (p_year IS NULL OR d.publicationYear = p_year)
    ORDER BY d.title COLLATE utf8mb4_0900_as_ci, d.documentCode, d.id;
END$$

DROP PROCEDURE IF EXISTS sp_get_document_detail$$
CREATE PROCEDURE sp_get_document_detail(IN p_document_id INT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT d.*, i.id AS itemId, i.itemCode, i.location, i.itemStatus
    FROM tblDocument d
    LEFT JOIN tblImportDetail incoming ON incoming.documentId = d.id
    LEFT JOIN tblItem i ON i.importDetailId = incoming.id
    WHERE d.id = p_document_id
    ORDER BY i.itemCode;
END$$

DROP PROCEDURE IF EXISTS sp_get_reader_borrow_statistics$$
CREATE PROCEDURE sp_get_reader_borrow_statistics(IN p_start_utc DATETIME, IN p_end_utc DATETIME)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT m.id, m.fullName, m.address, m.email, m.phoneNumber,
           r.readerCode, r.readerStatus, totals.borrowCount
    FROM tblReader r JOIN tblMember m ON m.id = r.memberId
    JOIN (
        SELECT readerId, COUNT(*) AS borrowCount
        FROM tblLoan WHERE checkoutDateTime >= p_start_utc AND checkoutDateTime < p_end_utc
        GROUP BY readerId
    ) totals ON totals.readerId = r.memberId
    ORDER BY totals.borrowCount DESC, r.memberId;
END$$

DROP PROCEDURE IF EXISTS sp_get_reader$$
CREATE PROCEDURE sp_get_reader(IN p_reader_id INT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT m.id, m.fullName, m.address, m.email, m.phoneNumber,
           r.readerCode, r.readerStatus
    FROM tblReader r JOIN tblMember m ON m.id = r.memberId
    WHERE r.memberId = p_reader_id;
END$$

DROP PROCEDURE IF EXISTS sp_get_loans_by_reader$$
CREATE PROCEDURE sp_get_loans_by_reader(IN p_reader_id INT, IN p_start_utc DATETIME, IN p_end_utc DATETIME)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT l.id, l.loanNumber, l.checkoutDateTime, ld.id AS detailId
    FROM tblLoan l
    LEFT JOIN tblLoanDetail ld ON ld.loanId = l.id
    WHERE l.readerId = p_reader_id AND l.checkoutDateTime >= p_start_utc AND l.checkoutDateTime < p_end_utc
    ORDER BY l.checkoutDateTime DESC, l.id, ld.id;
END$$

DROP PROCEDURE IF EXISTS sp_get_return_times$$
CREATE PROCEDURE sp_get_return_times(IN p_reader_id INT, IN p_start_utc DATETIME, IN p_end_utc DATETIME)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT rd.loanDetailId, r.returnDateTime
    FROM tblLoan l
    JOIN tblLoanDetail ld ON ld.loanId = l.id
    JOIN tblReturnDetail rd ON rd.loanDetailId = ld.id
    JOIN tblReturn r ON r.id = rd.returnId
    WHERE l.readerId = p_reader_id AND l.checkoutDateTime >= p_start_utc AND l.checkoutDateTime < p_end_utc;
END$$

DROP PROCEDURE IF EXISTS sp_get_loan_slip$$
CREATE PROCEDURE sp_get_loan_slip(IN p_reader_id INT, IN p_start_utc DATETIME, IN p_end_utc DATETIME, IN p_loan_id INT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
    SELECT l.id, l.loanNumber, l.checkoutDateTime, ld.id AS detailId, ld.dueDate,
           i.id AS itemId, i.itemCode, i.location, i.itemStatus,
           d.id AS documentId, d.documentCode, d.title AS documentTitle,
           rm.id AS readerId, rm.fullName AS readerName, rm.address AS readerAddress,
           rm.email AS readerEmail, rm.phoneNumber AS readerPhone, rd.readerCode, rd.readerStatus,
           m.id AS staffId, m.fullName AS staffName, m.address AS staffAddress,
           m.email AS staffEmail, m.phoneNumber AS staffPhone,
           e.employeeCode AS staffCode, e.position AS staffPosition
    FROM tblLoan l
    JOIN tblReader rd ON rd.memberId = l.readerId
    JOIN tblMember rm ON rm.id = rd.memberId
    JOIN tblEmployee e ON e.memberId = l.processedById
    JOIN tblMember m ON m.id = e.memberId
    LEFT JOIN tblLoanDetail ld ON ld.loanId = l.id
    LEFT JOIN tblItem i ON i.id = ld.itemId
    LEFT JOIN tblImportDetail incoming ON incoming.id = i.importDetailId
    LEFT JOIN tblDocument d ON d.id = incoming.documentId
    WHERE l.readerId = p_reader_id
      AND l.checkoutDateTime >= p_start_utc
      AND l.checkoutDateTime < p_end_utc
      AND l.id = p_loan_id
    ORDER BY l.checkoutDateTime DESC, l.id, ld.id;
END$$

DELIMITER ;
