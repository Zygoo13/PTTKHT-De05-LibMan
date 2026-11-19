package vn.edu.ptit.libman.model;

public class Member2 {
    private final int id;
    private final String fullName;
    private final String address;
    private final String email;
    private final String phoneNumber;
    private final Account2 account;

    public Member2(int id, String fullName, String address, String email, String phoneNumber, Account2 account) {
        this.id = id;
        this.fullName = fullName;
        this.address = address;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.account = account;
    }

    public int getId() {
        return id;
    }

    public String getFullName() {
        return fullName;
    }

    public String getAddress() {
        return address;
    }

    public String getEmail() {
        return email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public Account2 getAccount() {
        return account;
    }
}
