package vn.edu.ptit.libman.model;

import java.util.ArrayList;

public class Document2 {
    private final int id;
    private final String documentCode;
    private final String title;
    private final String author;
    private final String isbnOrIssn;
    private final String publisher;
    private final Integer publicationYear;
    private final String documentType;
    private final String subjectClassification;
    private final String edition;
    private final String description;
    private final boolean borrowable;
    private final ArrayList<Item2> items;

    public Document2(int id, String documentCode, String title, String author, String isbnOrIssn, String publisher, Integer publicationYear, String documentType, String subjectClassification, String edition, String description, boolean borrowable, ArrayList<Item2> items) {
        this.id = id;
        this.documentCode = documentCode;
        this.title = title;
        this.author = author;
        this.isbnOrIssn = isbnOrIssn;
        this.publisher = publisher;
        this.publicationYear = publicationYear;
        this.documentType = documentType;
        this.subjectClassification = subjectClassification;
        this.edition = edition;
        this.description = description;
        this.borrowable = borrowable;
        this.items = new ArrayList<>(items);
    }

    public int getId() {
        return id;
    }

    public String getDocumentCode() {
        return documentCode;
    }

    public String getTitle() {
        return title;
    }

    public String getAuthor() {
        return author;
    }

    public String getIsbnOrIssn() {
        return isbnOrIssn;
    }

    public String getPublisher() {
        return publisher;
    }

    public Integer getPublicationYear() {
        return publicationYear;
    }

    public String getDocumentType() {
        return documentType;
    }

    public String getSubjectClassification() {
        return subjectClassification;
    }

    public String getEdition() {
        return edition;
    }

    public String getDescription() {
        return description;
    }

    public boolean isBorrowable() {
        return borrowable;
    }

    public ArrayList<Item2> getItems() {
        return new ArrayList<>(items);
    }

    public void addItem(Item2 item) {
        items.add(item);
    }
}
