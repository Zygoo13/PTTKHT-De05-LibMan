package vn.edu.ptit.libman.dao;

import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HexFormat;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import vn.edu.ptit.libman.model.Account2;
import vn.edu.ptit.libman.model.LibraryManager2;
import vn.edu.ptit.libman.model.Member2;

public class AccountDAO extends DAO {
    public Member2 authenticate(String username, String password) throws SQLException {
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_find_active_account(?)}")) {
            statement.setString(1, username);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next() || !matchesPassword(password, rows.getString("password"))) {
                    return null;
                }
                int id = rows.getInt("id");
                Account2 account = new Account2(id, rows.getString("username"), null,
                        rows.getString("role"), rows.getString("status"));
                if ("MANAGER".equals(account.getRole())) {
                    try (PreparedStatement profile = connection.prepareStatement(
                            "SELECT employeeCode, position FROM tblEmployee WHERE memberId = ?")) {
                        profile.setInt(1, id);
                        try (ResultSet employee = profile.executeQuery()) {
                            if (!employee.next()) {
                                throw new SQLException("Missing employee profile for manager " + id, "23000");
                            }
                            return new LibraryManager2(id, rows.getString("fullName"), rows.getString("address"),
                                    rows.getString("email"), rows.getString("phoneNumber"), account,
                                    employee.getString("employeeCode"), employee.getString("position"));
                        }
                    }
                }
                return new Member2(id, rows.getString("fullName"), rows.getString("address"),
                        rows.getString("email"), rows.getString("phoneNumber"), account);
            }
        }
    }

    private boolean matchesPassword(String password, String stored) {
        if (stored == null || !stored.matches("\\{PBKDF2-SHA256\\}600000\\$[0-9a-fA-F]{32}\\$[0-9a-fA-F]{64}")) {
            return false;
        }
        String[] parts = stored.split("\\$");
        byte[] salt = HexFormat.of().parseHex(parts[1]);
        byte[] expected = HexFormat.of().parseHex(parts[2]);
        PBEKeySpec key = new PBEKeySpec(password.toCharArray(), salt, 600000, 256);
        try {
            byte[] actual = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(key).getEncoded();
            return MessageDigest.isEqual(expected, actual);
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("PBKDF2 unavailable", ex);
        } finally {
            key.clearPassword();
        }
    }
}
