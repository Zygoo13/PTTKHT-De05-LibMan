package vn.edu.ptit.libman.model;

import java.math.BigDecimal;
import java.time.Instant;

public abstract class Payment2 {
    private final int id;
    private final Instant paymentDateTime;
    private final BigDecimal amount;
    private final String paymentMethod;

    public Payment2(int id, Instant paymentDateTime, BigDecimal amount, String paymentMethod) {
        this.id = id;
        this.paymentDateTime = paymentDateTime;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
    }

    public int getId() {
        return id;
    }

    public Instant getPaymentDateTime() {
        return paymentDateTime;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }
}
