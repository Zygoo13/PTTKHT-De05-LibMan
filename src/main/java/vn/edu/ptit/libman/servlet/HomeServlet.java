package vn.edu.ptit.libman.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import vn.edu.ptit.libman.dao.AccountDAO;
import vn.edu.ptit.libman.model.Account2;
import vn.edu.ptit.libman.model.Member2;

@WebServlet(urlPatterns = {"", "/login", "/home", "/logout"})
public class HomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        if ("/logout".equals(request.getServletPath())) {
            response.sendError(405);
            return;
        }
        HttpSession session = request.getSession(false);
        Account2 account = session == null ? null : (Account2) session.getAttribute("account");
        if (account == null || !"ACTIVE".equals(account.getStatus())) {
            if (account != null) {
                session.invalidate();
            }
            if ("/home".equals(request.getServletPath())) {
                response.sendRedirect(request.getContextPath() + "/");
            } else {
                showLogin(request, response);
            }
        } else if ("/home".equals(request.getServletPath())) {
            request.getRequestDispatcher("/WEB-INF/view/thanhvien/gdChinh.jsp").forward(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        HttpSession session = request.getSession(false);
        if ("/logout".equals(request.getServletPath())) {
            if (session != null && session.getAttribute("account") != null) {
                String token = (String) session.getAttribute("logoutToken");
                if (token == null || !token.equals(request.getParameter("token"))) {
                    response.sendError(403);
                    return;
                }
                session.invalidate();
            }
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        if (!"/login".equals(request.getServletPath())) {
            response.sendError(405);
            return;
        }

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        username = username == null ? "" : username.strip();
        Member2 member = null;
        if (!username.isEmpty() && username.length() <= 80
                && password != null && !password.isEmpty() && password.length() <= 256) {
            try {
                AccountDAO accounts = new AccountDAO();
                member = accounts.authenticate(username, password);
            } catch (SQLException ex) {
                getServletContext().log("LibMan JDBC read failed: " + ex.getSQLState());
                response.setStatus(503);
                request.setAttribute("error", "Chưa thể đọc dữ liệu thư viện. Hãy kiểm tra kết nối MySQL rồi thử lại.");
                request.getRequestDispatcher("/WEB-INF/view/dungchung/gdLoi.jsp").forward(request, response);
                return;
            }
        }
        if (member == null) {
            response.setStatus(401);
            request.setAttribute("username", username);
            request.setAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng.");
            showLogin(request, response);
            return;
        }

        if (session != null) {
            session.invalidate();
        }
        session = request.getSession();
        session.setAttribute("account", member.getAccount());
        session.setAttribute("fullName", member.getFullName());
        session.setAttribute("logoutToken", UUID.randomUUID().toString());
        response.sendRedirect(request.getContextPath() + "/home");
    }

    private void showLogin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/view/thanhvien/gdDangNhap.jsp").forward(request, response);
    }
}
