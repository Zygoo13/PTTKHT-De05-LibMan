package vn.edu.ptit.libman.model;

public class Employee2 extends Member2 {
    private final String employeeCode;
    private final String position;

    public Employee2(int id, String fullName, String address, String email, String phoneNumber, Account2 account, String employeeCode, String position) {
        super(id, fullName, address, email, phoneNumber, account);
        this.employeeCode = employeeCode;
        this.position = position;
    }

    public String getEmployeeCode() {
        return employeeCode;
    }

    public String getPosition() {
        return position;
    }
}
