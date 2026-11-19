CREATE DATABASE IF NOT EXISTS libman CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci;
USE libman;

CREATE TABLE IF NOT EXISTS tblMember (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(80) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` VARCHAR(20) NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `fullName` VARCHAR(160) NOT NULL,
    `address` VARCHAR(350) NULL,
    `email` VARCHAR(254) NOT NULL,
    `phoneNumber` VARCHAR(32) NULL,
    UNIQUE (username)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblReader (
    `memberId` INT NOT NULL PRIMARY KEY,
    `readerCode` VARCHAR(64) NOT NULL,
    `readerStatus` VARCHAR(20) NOT NULL,
    FOREIGN KEY (memberId) REFERENCES tblMember(id),
    UNIQUE (readerCode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblEmployee (
    `memberId` INT NOT NULL PRIMARY KEY,
    `employeeCode` VARCHAR(64) NOT NULL,
    `position` VARCHAR(100) NOT NULL,
    FOREIGN KEY (memberId) REFERENCES tblMember(id),
    UNIQUE (employeeCode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblReaderCard (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `cardNumber` VARCHAR(64) NOT NULL,
    `issueDate` DATE NOT NULL,
    `issueSequence` INT NOT NULL,
    `expiryDate` DATE NOT NULL,
    `cardStatus` VARCHAR(20) NOT NULL,
    `readerId` INT NOT NULL,
    FOREIGN KEY (readerId) REFERENCES tblReader(memberId),
    UNIQUE (cardNumber),
    UNIQUE (readerId, issueSequence),
    CHECK (issueSequence > 0 AND expiryDate >= issueDate)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblDocument (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `documentCode` VARCHAR(64) NOT NULL,
    `title` VARCHAR(500) NOT NULL,
    `author` VARCHAR(300) NULL,
    `isbnOrIssn` VARCHAR(40) NULL,
    `publisher` VARCHAR(300) NULL,
    `publicationYear` INT NULL,
    `documentType` VARCHAR(20) NOT NULL,
    `subjectClassification` VARCHAR(100) NULL,
    `edition` VARCHAR(100) NULL,
    `description` TEXT NULL,
    `borrowable` BIT(1) NOT NULL,
    UNIQUE (documentCode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblSupplier (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `supplierCode` VARCHAR(64) NOT NULL,
    `supplierName` VARCHAR(250) NOT NULL,
    `address` VARCHAR(350) NULL,
    `phoneNumber` VARCHAR(32) NULL,
    `email` VARCHAR(254) NULL,
    `description` TEXT NULL,
    UNIQUE (supplierCode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblImport (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `importNumber` VARCHAR(64) NOT NULL,
    `confirmationDateTime` TIMESTAMP NOT NULL,
    `processedById` INT NOT NULL,
    `supplierId` INT NOT NULL,
    UNIQUE (importNumber),
    FOREIGN KEY (processedById) REFERENCES tblEmployee(memberId),
    FOREIGN KEY (supplierId) REFERENCES tblSupplier(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblImportDetail (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `quantity` INT NOT NULL,
    `unitPrice` DECIMAL(18,0) NOT NULL,
    `documentId` INT NOT NULL,
    `importId` INT NOT NULL,
    FOREIGN KEY (documentId) REFERENCES tblDocument(id),
    FOREIGN KEY (importId) REFERENCES tblImport(id),
    CHECK (quantity > 0 AND unitPrice >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblItem (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemCode` VARCHAR(64) NOT NULL,
    `location` VARCHAR(180) NOT NULL,
    `itemStatus` VARCHAR(20) NOT NULL,
    `importDetailId` INT NOT NULL,
    UNIQUE (itemCode),
    FOREIGN KEY (importDetailId) REFERENCES tblImportDetail(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblLoan (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `loanNumber` VARCHAR(64) NOT NULL,
    `checkoutDateTime` TIMESTAMP NOT NULL,
    `readerId` INT NOT NULL,
    `processedById` INT NOT NULL,
    UNIQUE (loanNumber),
    FOREIGN KEY (readerId) REFERENCES tblReader(memberId),
    FOREIGN KEY (processedById) REFERENCES tblEmployee(memberId),
    INDEX ix_loan_date_reader (checkoutDateTime, readerId),
    INDEX ix_loan_reader_date (readerId, checkoutDateTime)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblLoanDetail (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `dueDate` DATE NOT NULL,
    `loanId` INT NOT NULL,
    `itemId` INT NOT NULL,
    FOREIGN KEY (loanId) REFERENCES tblLoan(id),
    FOREIGN KEY (itemId) REFERENCES tblItem(id),
    UNIQUE (loanId, itemId)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblReturn (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `returnNumber` VARCHAR(64) NOT NULL,
    `returnDateTime` TIMESTAMP NOT NULL,
    `processedById` INT NOT NULL,
    UNIQUE (returnNumber),
    FOREIGN KEY (processedById) REFERENCES tblEmployee(memberId)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblReturnDetail (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `condition` VARCHAR(20) NOT NULL,
    `returnId` INT NOT NULL,
    `loanDetailId` INT NOT NULL,
    FOREIGN KEY (returnId) REFERENCES tblReturn(id),
    FOREIGN KEY (loanDetailId) REFERENCES tblLoanDetail(id),
    UNIQUE (loanDetailId)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblFine (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `reason` VARCHAR(20) NOT NULL,
    `amount` DECIMAL(18,0) NOT NULL,
    `loanDetailId` INT NOT NULL,
    `assessedById` INT NOT NULL,
    FOREIGN KEY (loanDetailId) REFERENCES tblLoanDetail(id),
    FOREIGN KEY (assessedById) REFERENCES tblEmployee(memberId),
    UNIQUE (loanDetailId, reason),
    CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblFinePayment (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `receiptNumber` VARCHAR(64) NOT NULL,
    `paymentDateTime` TIMESTAMP NOT NULL,
    `amount` DECIMAL(18,0) NOT NULL,
    `paymentMethod` VARCHAR(40) NOT NULL,
    `fineId` INT NOT NULL,
    `processedById` INT NOT NULL,
    UNIQUE (receiptNumber),
    UNIQUE (fineId),
    FOREIGN KEY (fineId) REFERENCES tblFine(id),
    FOREIGN KEY (processedById) REFERENCES tblEmployee(memberId),
    CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tblSupplierPayment (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `paymentReference` VARCHAR(120) NULL,
    `paymentDateTime` TIMESTAMP NOT NULL,
    `amount` DECIMAL(18,0) NOT NULL,
    `paymentMethod` VARCHAR(40) NOT NULL,
    `processedById` INT NOT NULL,
    `importId` INT NOT NULL,
    UNIQUE (importId),
    FOREIGN KEY (importId) REFERENCES tblImport(id),
    FOREIGN KEY (processedById) REFERENCES tblEmployee(memberId),
    CHECK (amount > 0)
) ENGINE=InnoDB;
