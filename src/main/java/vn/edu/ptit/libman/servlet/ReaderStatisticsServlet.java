package vn.edu.ptit.libman.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import vn.edu.ptit.libman.dao.LoanDAO;
import vn.edu.ptit.libman.model.Account2;
import vn.edu.ptit.libman.model.Document2;
import vn.edu.ptit.libman.model.Loan2;
import vn.edu.ptit.libman.model.LoanDetail2;
import vn.edu.ptit.libman.model.Reader2;
import vn.edu.ptit.libman.model.ReaderStatistics2;

@WebServlet(urlPatterns = {"/reports/readers", "/reports/readers/loans",
    "/reports/readers/loans/detail", "/reports/readers/slip"})
public class ReaderStatisticsServlet extends HttpServlet {
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/uuuu", Locale.ROOT);
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("dd/MM/uuuu HH:mm", Locale.ROOT)
            .withZone(LoanDAO.LIBRARY_ZONE);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        HttpSession session = request.getSession(false);
        Account2 account = session == null ? null : (Account2) session.getAttribute("account");
        if (account == null || !"ACTIVE".equals(account.getStatus())) {
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        if (!"MANAGER".equals(account.getRole())) {
            error(request, response, 403, "Chỉ người quản lý được xem báo cáo này.");
            return;
        }
        request.setAttribute("section", "reports");
        String path = request.getServletPath();
        String start = request.getParameter("startDate");
        String end = request.getParameter("endDate");
        request.setAttribute("startDate", start);
        request.setAttribute("endDate", end);

        LocalDate startDate = readDate(start);
        LocalDate endDate = readDate(end);
        boolean validPeriod = startDate != null && endDate != null && !startDate.isAfter(endDate);
        try {
            if ("/reports/readers".equals(path)) {
                showReport(request, response, startDate, endDate, validPeriod);
                return;
            }

            int readerId = readId(request, "readerId");
            boolean isLoanList = "/reports/readers/loans".equals(path);
            int loanId = isLoanList ? 0 : readId(request, "loanId");
            if (!validPeriod || readerId == 0 || (!isLoanList && loanId == 0)) {
                error(request, response, 400, "Kỳ thống kê hoặc mã định danh độc giả, phiếu mượn không hợp lệ.");
                return;
            }

            request.setAttribute("readerId", readerId);
            request.setAttribute("periodLabel", DATE.format(startDate) + " – " + DATE.format(endDate));
            if (isLoanList) {
                showLoans(request, response, readerId, startDate, endDate);
            } else if ("/reports/readers/slip".equals(path)) {
                showLoanSlip(request, response, readerId, loanId, startDate, endDate);
            } else {
                showLoan(request, response, readerId, loanId, startDate, endDate);
            }
        } catch (SQLException ex) {
            getServletContext().log("LibMan JDBC read failed: " + ex.getSQLState());
            error(request, response, 503,
                    "Chưa thể đọc dữ liệu thư viện. Hãy kiểm tra kết nối MySQL rồi thử lại.");
        }
    }

    private LocalDate readDate(String value) {
        if (value == null || value.length() != 10) {
            return null;
        }
        try {
            LocalDate date = LocalDate.parse(value);
            return date.getYear() > 0 ? date : null;
        } catch (DateTimeParseException ex) {
            return null;
        }
    }

    private void showReport(HttpServletRequest request, HttpServletResponse response,
            LocalDate startDate, LocalDate endDate, boolean validPeriod)
            throws ServletException, IOException, SQLException {
        if (validPeriod) {
            LoanDAO loans = new LoanDAO();
            ArrayList<ReaderStatistics2> statistics = loans.getReaderBorrowStatistics(startDate, endDate);
            request.setAttribute("statistics", statistics);
        } else if (request.getAttribute("startDate") != null || request.getAttribute("endDate") != null) {
            response.setStatus(400);
            request.setAttribute("error", "Nhập đủ hai ngày hợp lệ. Từ ngày phải trước hoặc bằng Đến ngày.");
        }
        request.getRequestDispatcher("/WEB-INF/view/quanli/gdThongKeDocGia.jsp").forward(request, response);
    }

    private void showLoans(HttpServletRequest request, HttpServletResponse response,
            int readerId, LocalDate startDate, LocalDate endDate)
            throws ServletException, IOException, SQLException {
        LoanDAO loans = new LoanDAO();
        Reader2 reader = loans.getReader(readerId);
        if (reader == null) {
            error(request, response, 404, "Không tìm thấy độc giả.");
            return;
        }
        ArrayList<Loan2> readerLoans = loans.getLoansByReader(reader, startDate, endDate);
        if (readerLoans.isEmpty()) {
            error(request, response, 404, "Độc giả không có lần mượn trong kỳ thống kê đã chọn.");
            return;
        }
        Map<Integer, String> checkoutLabels = new HashMap<>();
        for (Loan2 loan : readerLoans) {
            checkoutLabels.put(loan.getId(), TIME.format(loan.getCheckoutDateTime()));
        }
        request.setAttribute("reader", reader);
        request.setAttribute("loans", readerLoans);
        request.setAttribute("checkoutLabels", checkoutLabels);
        request.getRequestDispatcher("/WEB-INF/view/quanli/gdLuotMuonDocGia.jsp").forward(request, response);
    }

    private void showLoan(HttpServletRequest request, HttpServletResponse response,
            int readerId, int loanId, LocalDate startDate, LocalDate endDate)
            throws ServletException, IOException, SQLException {
        LoanDAO loans = new LoanDAO();
        Map<Integer, Document2> documentsByItemId = new HashMap<>();
        Loan2 loan = loans.getLoanSlip(readerId, loanId, startDate, endDate, documentsByItemId);
        if (loan == null) {
            error(request, response, 404, "Phiếu mượn không thuộc độc giả hoặc kỳ báo cáo đang xem.");
            return;
        }
        ArrayList<LoanDetail2> loanDetails = loan.getLoanDetails();
        if (loanDetails.isEmpty()) {
            error(request, response, 409, "Phiếu mượn không có bản tài liệu. Không thể mở chi tiết hoặc in phiếu.");
            return;
        }
        Map<Integer, String> detailDueDates = new HashMap<>();
        for (LoanDetail2 detail : loanDetails) {
            detailDueDates.put(detail.getId(), DATE.format(detail.getDueDate()));
        }
        request.setAttribute("loan", loan);
        request.setAttribute("checkoutLabel", TIME.format(loan.getCheckoutDateTime()));
        request.setAttribute("detailDueDates", detailDueDates);
        Map<Integer, String> returnLabels = new HashMap<>();
        loans.getReturnTimes(readerId, startDate, endDate)
                .forEach((id, time) -> returnLabels.put(id, TIME.format(time)));
        request.setAttribute("returnLabels", returnLabels);
        request.setAttribute("documentsByItemId", documentsByItemId);
        request.getRequestDispatcher("/WEB-INF/view/quanli/gdChiTietPhieuMuon.jsp").forward(request, response);
    }

    private void showLoanSlip(HttpServletRequest request, HttpServletResponse response,
            int readerId, int loanId, LocalDate startDate, LocalDate endDate)
            throws ServletException, IOException, SQLException {
        LoanDAO loans = new LoanDAO();
        Map<Integer, Document2> documentsByItemId = new HashMap<>();
        Loan2 loan = loans.getLoanSlip(readerId, loanId, startDate, endDate, documentsByItemId);
        if (loan == null) {
            error(request, response, 404, "Phiếu mượn không thuộc độc giả hoặc kỳ báo cáo đang xem.");
            return;
        }
        ArrayList<LoanDetail2> loanDetails = loan.getLoanDetails();
        if (loanDetails.isEmpty()) {
            error(request, response, 409, "Phiếu mượn không có bản tài liệu. Không thể mở chi tiết hoặc in phiếu.");
            return;
        }
        Map<Integer, String> detailDueDates = new HashMap<>();
        for (LoanDetail2 detail : loanDetails) {
            detailDueDates.put(detail.getId(), DATE.format(detail.getDueDate()));
        }
        request.setAttribute("loan", loan);
        request.setAttribute("checkoutLabel", TIME.format(loan.getCheckoutDateTime()));
        request.setAttribute("detailDueDates", detailDueDates);
        request.setAttribute("documentsByItemId", documentsByItemId);
        request.getRequestDispatcher("/WEB-INF/view/quanli/gdInPhieuMuon.jsp").forward(request, response);
    }

    private void error(HttpServletRequest request, HttpServletResponse response, int status, String message)
            throws ServletException, IOException {
        response.setStatus(status);
        request.setAttribute("error", message);
        request.getRequestDispatcher("/WEB-INF/view/dungchung/gdLoi.jsp").forward(request, response);
    }

    private static int readId(HttpServletRequest request, String parameter) {
        try {
            return Math.max(0, Integer.parseInt(request.getParameter(parameter)));
        } catch (NumberFormatException ex) {
            return 0;
        }
    }
}
