package vn.edu.ptit.libman.model;

import java.time.Instant;
import java.util.ArrayList;

public class Loan2 {
    private final int id;
    private final String loanNumber;
    private final Instant checkoutDateTime;
    private final Reader2 reader;
    private final LibraryStaff2 processedBy;
    private final ArrayList<LoanDetail2> loanDetails;

    public Loan2(int id, String loanNumber, Instant checkoutDateTime, Reader2 reader, LibraryStaff2 processedBy, ArrayList<LoanDetail2> loanDetails) {
        this.id = id;
        this.loanNumber = loanNumber;
        this.checkoutDateTime = checkoutDateTime;
        this.reader = reader;
        this.processedBy = processedBy;
        this.loanDetails = new ArrayList<>(loanDetails);
    }

    public int getId() {
        return id;
    }

    public String getLoanNumber() {
        return loanNumber;
    }

    public Instant getCheckoutDateTime() {
        return checkoutDateTime;
    }

    public Reader2 getReader() {
        return reader;
    }

    public LibraryStaff2 getProcessedBy() {
        return processedBy;
    }

    public ArrayList<LoanDetail2> getLoanDetails() {
        return new ArrayList<>(loanDetails);
    }

    public void addLoanDetail(LoanDetail2 detail) {
        loanDetails.add(detail);
    }
}
