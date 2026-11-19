package vn.edu.ptit.libman.model;

import java.math.BigDecimal;
import java.time.Instant;

public class FinePayment2 extends Payment2 {
    private final String receiptNumber;
    private final LibraryStaff2 processedBy;
    private final Reader2 payer;

    public FinePayment2(int id, Instant paymentDateTime, BigDecimal amount, String paymentMethod, String receiptNumber, LibraryStaff2 processedBy, Reader2 payer) {
        super(id, paymentDateTime, amount, paymentMethod);
        this.receiptNumber = receiptNumber;
        this.processedBy = processedBy;
        this.payer = payer;
    }

    public String getReceiptNumber() {
        return receiptNumber;
    }

    public LibraryStaff2 getProcessedBy() {
        return processedBy;
    }

    public Reader2 getPayer() {
        return payer;
    }
}
