# LibMan — Thư viện PTIT

- **Môn học:** Phân tích và thiết kế hệ thống thông tin
- **Họ và tên:** Hoàng Quốc Anh
- **Mã sinh viên:** B23DCCN022
- **Đề số:** 05

## Cài đặt

Yêu cầu JDK 17, Maven, Tomcat 9 và MySQL 8.0.

1. Mở MySQL và chạy lần lượt các tệp trong thư mục `database`: `01_schema.sql`, `02_seed.sql`, `04_stored_procedures.sql`, `03_verify.sql`.
2. Mở `DAO.java` và thay `MAT_KHAU_MYSQL` bằng mật khẩu MySQL trên máy bạn. Nếu dùng tài khoản MySQL khác, sửa cả tên `root`.
3. Mở project trong NetBeans, chọn Tomcat 9 rồi bấm **Run Project**. Sau đó mở [LibMan](http://localhost:8080/libman/).

## Tài khoản demo

Mật khẩu chung: `12345678`.

| Tài khoản | Vai trò |
|---|---|
| `reader001` | Độc giả |
| `librarystaff001` | Nhân viên thư viện |
| `manager001` | Người quản lý |

