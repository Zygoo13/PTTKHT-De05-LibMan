package vn.edu.ptit.libman.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DAO {
    private Connection conn;

    public Connection getConnection() throws SQLException {
        if (conn == null || conn.isClosed()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
            } catch (ClassNotFoundException ex) {
                throw new SQLException("Không tìm thấy MySQL JDBC driver", ex);
            }

            String url = "jdbc:mysql://127.0.0.1:3306/libman"
                    + "?connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true"
                    + "&preserveInstants=true&characterEncoding=UTF-8";
            conn = DriverManager.getConnection(url, "root", "MAT_KHAU_MYSQL");
        }
        return conn;
    }
}
