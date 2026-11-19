package vn.edu.ptit.libman.model;

import java.time.LocalDate;

public class ReaderCard2 {
    private final int id;
    private final String cardNumber;
    private final LocalDate issueDate;
    private final int issueSequence;
    private final LocalDate expiryDate;
    private final String cardStatus;

    public ReaderCard2(int id, String cardNumber, LocalDate issueDate, int issueSequence, LocalDate expiryDate, String cardStatus) {
        this.id = id;
        this.cardNumber = cardNumber;
        this.issueDate = issueDate;
        this.issueSequence = issueSequence;
        this.expiryDate = expiryDate;
        this.cardStatus = cardStatus;
    }

    public int getId() {
        return id;
    }

    public String getCardNumber() {
        return cardNumber;
    }

    public LocalDate getIssueDate() {
        return issueDate;
    }

    public int getIssueSequence() {
        return issueSequence;
    }

    public LocalDate getExpiryDate() {
        return expiryDate;
    }

    public String getCardStatus() {
        return cardStatus;
    }
}
