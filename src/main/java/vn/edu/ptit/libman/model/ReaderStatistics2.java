package vn.edu.ptit.libman.model;

public class ReaderStatistics2 extends Reader2 {
    private final int borrowCount;

    public ReaderStatistics2(Reader2 reader, int borrowCount) {
        super(reader.getId(), reader.getFullName(), reader.getAddress(), reader.getEmail(),
                reader.getPhoneNumber(), reader.getAccount(), reader.getReaderCode(),
                reader.getReaderStatus(), reader.getCards());
        this.borrowCount = borrowCount;
    }

    public int getBorrowCount() {
        return borrowCount;
    }
}
