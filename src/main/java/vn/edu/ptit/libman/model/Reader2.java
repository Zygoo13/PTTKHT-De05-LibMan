package vn.edu.ptit.libman.model;

import java.util.ArrayList;

public class Reader2 extends Member2 {
    private final String readerCode;
    private final String readerStatus;
    private final ArrayList<ReaderCard2> cards;

    public Reader2(int id, String fullName, String address, String email, String phoneNumber, Account2 account, String readerCode, String readerStatus, ArrayList<ReaderCard2> cards) {
        super(id, fullName, address, email, phoneNumber, account);
        this.readerCode = readerCode;
        this.readerStatus = readerStatus;
        this.cards = new ArrayList<>(cards);
    }

    public String getReaderCode() {
        return readerCode;
    }

    public String getReaderStatus() {
        return readerStatus;
    }

    public ArrayList<ReaderCard2> getCards() {
        return new ArrayList<>(cards);
    }

    public void addCard(ReaderCard2 card) {
        cards.add(card);
    }
}
