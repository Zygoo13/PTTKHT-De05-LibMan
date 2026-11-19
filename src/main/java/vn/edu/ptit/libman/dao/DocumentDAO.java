package vn.edu.ptit.libman.dao;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import vn.edu.ptit.libman.model.Document2;
import vn.edu.ptit.libman.model.Item2;

public class DocumentDAO extends DAO {
    public ArrayList<Document2> searchDocuments(
            String keyword, String field, String type, Integer year)
            throws SQLException {
        ArrayList<Document2> documents = new ArrayList<>();
        String pattern = "%" + keyword.replace("!", "!!").replace("%", "!%").replace("_", "!_") + "%";
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_search_documents(?, ?, ?, ?, ?)}")) {
            statement.setString(1, keyword);
            statement.setString(2, field);
            statement.setString(3, pattern);
            statement.setString(4, type);
            statement.setObject(5, year, Types.INTEGER);
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    // A1 chỉ nạp các trường dùng cho danh sách kết quả.
                    documents.add(new Document2(
                            rows.getInt("id"), rows.getString("documentCode"),
                            rows.getString("title"), rows.getString("author"),
                            null, null, // ISBN/ISSN, nhà xuất bản
                            rows.getObject("publicationYear", Integer.class),
                            rows.getString("documentType"),
                            null, null, null, // Chủ đề, ấn bản, mô tả
                            rows.getBoolean("borrowable"),
                            new ArrayList<>()));
                }
            }
        }
        return documents;
    }

    public Document2 getDocumentDetail(int documentId) throws SQLException {
        try (Connection connection = getConnection();
                CallableStatement statement = connection.prepareCall("{CALL sp_get_document_detail(?)}")) {
            statement.setInt(1, documentId);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return null;
                }
                Document2 document = new Document2(
                        rows.getInt("id"), rows.getString("documentCode"),
                        rows.getString("title"), rows.getString("author"),
                        rows.getString("isbnOrIssn"), rows.getString("publisher"),
                        rows.getObject("publicationYear", Integer.class),
                        rows.getString("documentType"), rows.getString("subjectClassification"),
                        rows.getString("edition"), rows.getString("description"),
                        rows.getBoolean("borrowable"), new ArrayList<>());

                do {
                    Integer itemId = rows.getObject("itemId", Integer.class);
                    if (itemId != null) {
                        document.addItem(new Item2(
                                itemId, rows.getString("itemCode"),
                                rows.getString("location"), rows.getString("itemStatus")));
                    }
                } while (rows.next());
                return document;
            }
        }
    }

    public int getAvailableCount(Document2 document) {
        int count = 0;
        for (Item2 item : document.getItems()) {
            if ("AVAILABLE".equals(item.getItemStatus())) {
                count++;
            }
        }
        return count;
    }
}
