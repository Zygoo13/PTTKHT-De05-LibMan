package vn.edu.ptit.libman.model;

import java.math.BigDecimal;

public class Fine2 {
    private final int id;
    private final String reason;
    private final BigDecimal amount;
    private final LibraryStaff2 assessedBy;
    private final FinePayment2 payment;

    public Fine2(int id, String reason, BigDecimal amount, LibraryStaff2 assessedBy, FinePayment2 payment) {
        this.id = id;
        this.reason = reason;
        this.amount = amount;
        this.assessedBy = assessedBy;
        this.payment = payment;
    }

    public int getId() {
        return id;
    }

    public String getReason() {
        return reason;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public LibraryStaff2 getAssessedBy() {
        return assessedBy;
    }

    public FinePayment2 getPayment() {
        return payment;
    }
}
