package vn.edu.ptit.libman.dao;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import vn.edu.ptit.libman.model.Document2;
import vn.edu.ptit.libman.model.Item2;
import vn.edu.ptit.libman.model.LibraryStaff2;
import vn.edu.ptit.libman.model.Loan2;
import vn.edu.ptit.libman.model.LoanDetail2;
import vn.edu.ptit.libman.model.Reader2;
import vn.edu.ptit.libman.model.ReaderStatistics2;

public class LoanDAO extends DAO {
    public static final ZoneId LIBRARY_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    public ArrayList<ReaderStatistics2> getReaderBorrowStatistics(
            LocalDate startDate, LocalDate endDate) throws SQLException {
        ArrayList<ReaderStatistics2> results = new ArrayList<>();
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_reader_borrow_statistics(?, ?)}")) {
            statement.setObject(1, atStartUtc(startDate));
            statement.setObject(2, atStartUtc(endDate.plusDays(1)));
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    int id = rows.getInt("id");
                    Reader2 reader = new Reader2(id, rows.getString("fullName"), rows.getString("address"),
                            rows.getString("email"), rows.getString("phoneNumber"), null,
                            rows.getString("readerCode"), rows.getString("readerStatus"), new ArrayList<>());
                    results.add(new ReaderStatistics2(reader, rows.getInt("borrowCount")));
                }
            }
        }
        return results;
    }

    public Reader2 getReader(int readerId) throws SQLException {
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_reader(?)}")) {
            statement.setInt(1, readerId);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return null;
                }
                int id = rows.getInt("id");
                return new Reader2(id, rows.getString("fullName"), rows.getString("address"),
                        rows.getString("email"), rows.getString("phoneNumber"), null,
                        rows.getString("readerCode"), rows.getString("readerStatus"), new ArrayList<>());
            }
        }
    }

    public ArrayList<Loan2> getLoansByReader(
            Reader2 reader, LocalDate startDate, LocalDate endDate) throws SQLException {
        ArrayList<Loan2> results = new ArrayList<>();
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_loans_by_reader(?, ?, ?)}")) {
            statement.setInt(1, reader.getId());
            statement.setObject(2, atStartUtc(startDate));
            statement.setObject(3, atStartUtc(endDate.plusDays(1)));
            try (ResultSet rows = statement.executeQuery()) {
                Loan2 loan = null;
                while (rows.next()) {
                    int id = rows.getInt("id");
                    if (loan == null || loan.getId() != id) {
                        // The loan list needs only the loan header and detail IDs.
                        loan = new Loan2(id, rows.getString("loanNumber"), instant(rows, "checkoutDateTime"),
                                reader, null, new ArrayList<>());
                        results.add(loan);
                    }
                    Integer detailId = rows.getObject("detailId", Integer.class);
                    if (detailId != null) {
                        loan.addLoanDetail(new LoanDetail2(detailId, null, null, new ArrayList<>()));
                    }
                }
            }
        }
        return results;
    }

    public Map<Integer, Instant> getReturnTimes(
            int readerId, LocalDate startDate, LocalDate endDate) throws SQLException {
        Map<Integer, Instant> times = new HashMap<>();
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_return_times(?, ?, ?)}")) {
            statement.setInt(1, readerId);
            statement.setObject(2, atStartUtc(startDate));
            statement.setObject(3, atStartUtc(endDate.plusDays(1)));
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    times.put(rows.getInt("loanDetailId"),
                            rows.getObject("returnDateTime", LocalDateTime.class).toInstant(ZoneOffset.UTC));
                }
            }
            return times;
        }
    }

    public Loan2 getLoanSlip(int readerId, int loanId, LocalDate startDate, LocalDate endDate,
            Map<Integer, Document2> documentsByItemId) throws SQLException {
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_loan_slip(?, ?, ?, ?)}")) {
            statement.setInt(1, readerId);
            statement.setObject(2, atStartUtc(startDate));
            statement.setObject(3, atStartUtc(endDate.plusDays(1)));
            statement.setInt(4, loanId);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return null;
                }

                Reader2 reader = new Reader2(
                        rows.getInt("readerId"), rows.getString("readerName"),
                        rows.getString("readerAddress"), rows.getString("readerEmail"),
                        rows.getString("readerPhone"), null,
                        rows.getString("readerCode"), rows.getString("readerStatus"),
                        new ArrayList<>());

                LibraryStaff2 staff = new LibraryStaff2(
                        rows.getInt("staffId"), rows.getString("staffName"),
                        rows.getString("staffAddress"), rows.getString("staffEmail"),
                        rows.getString("staffPhone"), null,
                        rows.getString("staffCode"), rows.getString("staffPosition"));

                Loan2 loan = new Loan2(
                        rows.getInt("id"), rows.getString("loanNumber"),
                        instant(rows, "checkoutDateTime"), reader, staff, new ArrayList<>());

                Map<Integer, Document2> documentsById = new HashMap<>();

                do {
                    Integer detailId = rows.getObject("detailId", Integer.class);
                    if (detailId != null) {
                        Item2 item = new Item2(
                                rows.getInt("itemId"), rows.getString("itemCode"),
                                rows.getString("location"), rows.getString("itemStatus"));
                        loan.addLoanDetail(new LoanDetail2(
                                detailId, rows.getObject("dueDate", LocalDate.class),
                                item, new ArrayList<>()));

                        Integer documentId = rows.getObject("documentId", Integer.class);
                        if (documentId != null) {
                            Document2 document = documentsById.get(documentId);
                            if (document == null) {
                                // B3 và B4 chỉ cần mã và tên đầu tài liệu.
                                document = new Document2(
                                        documentId, rows.getString("documentCode"),
                                        rows.getString("documentTitle"),
                                        null, null, null, null, null, null, null, null,
                                        false, new ArrayList<>());
                                documentsById.put(documentId, document);
                            }
                            documentsByItemId.put(item.getId(), document);
                        }
                    }
                } while (rows.next());

                return loan;
            }
        }
    }

    private static LocalDateTime atStartUtc(LocalDate day) {
        return LocalDateTime.ofInstant(day.atStartOfDay(LIBRARY_ZONE).toInstant(), ZoneOffset.UTC);
    }

    private static Instant instant(ResultSet rows, String column) throws SQLException {
        return rows.getObject(column, LocalDateTime.class).toInstant(ZoneOffset.UTC);
    }
}
