package vn.edu.ptit.libman.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import vn.edu.ptit.libman.dao.DocumentDAO;
import vn.edu.ptit.libman.model.Account2;
import vn.edu.ptit.libman.model.Document2;
import vn.edu.ptit.libman.model.Item2;

@WebServlet(urlPatterns = {"/documents", "/documents/detail"})
public class DocumentServlet extends HttpServlet {

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
        if (!"READER".equals(account.getRole())) {
            error(request, response, 403, "Chức năng tra cứu dành cho độc giả.");
            return;
        }
        request.setAttribute("section", "documents");
        String keyword = parameter(request, "keyword");
        String requestedField = parameter(request, "field");
        String field = switch (requestedField) {
            case "title", "author", "code", "isbn" -> requestedField;
            default -> "all";
        };

        String requestedType = parameter(request, "type");
        String type = switch (requestedType) {
            case "BOOK", "TEXTBOOK", "MAGAZINE", "OTHER" -> requestedType;
            default -> "";
        };
        String year = parameter(request, "year");
        request.setAttribute("keyword", keyword);
        request.setAttribute("field", field);
        request.setAttribute("type", type);
        request.setAttribute("year", year);

        try {
            if ("/documents/detail".equals(request.getServletPath())) {
                showDocumentDetail(request, response);
            } else {
                showSearchPage(request, response, keyword, field, type, year);
            }
        } catch (SQLException ex) {
            getServletContext().log("Thư viện PTIT JDBC read failed: " + ex.getSQLState());
            error(request, response, 503,
                    "Chưa thể đọc dữ liệu thư viện. Hãy kiểm tra kết nối MySQL rồi thử lại.");
        }
    }

    private String parameter(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.strip();
    }

    private void showSearchPage(HttpServletRequest request, HttpServletResponse response,
            String keyword, String field, String type, String year)
            throws ServletException, IOException, SQLException {
        if (keyword.length() > 500 || (!year.isEmpty() && !year.matches("[1-9][0-9]{3}"))) {
            response.setStatus(400);
            request.setAttribute("error", "Từ khóa tối đa 500 ký tự. Năm xuất bản cần có bốn chữ số.");
        } else if (!keyword.isEmpty() || !type.isEmpty() || !year.isEmpty()) {
            DocumentDAO documents = new DocumentDAO();
            Integer publicationYear = year.isEmpty() ? null : Integer.valueOf(year);
            ArrayList<Document2> results = documents.searchDocuments(keyword, field, type, publicationYear);
            request.setAttribute("documents", results);
        }
        request.getRequestDispatcher("/WEB-INF/view/bandoc/gdTimTaiLieu.jsp").forward(request, response);
    }

    private void showDocumentDetail(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        int id = readId(request, "documentId");
        DocumentDAO documents = new DocumentDAO();
        Document2 document = id == 0 ? null : documents.getDocumentDetail(id);
        if (document == null) {
            response.setStatus(id == 0 ? 400 : 404);
            request.setAttribute("error", "Không tìm thấy tài liệu. Hãy quay lại danh sách tìm kiếm.");
        } else {
            ArrayList<Item2> items = document.getItems();
            int availableCount = documents.getAvailableCount(document);

            request.setAttribute("document", document);
            request.setAttribute("items", items);
            request.setAttribute("availableCount", availableCount);
        }
        request.getRequestDispatcher("/WEB-INF/view/bandoc/gdChiTietTaiLieu.jsp").forward(request, response);
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
