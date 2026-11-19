package vn.edu.ptit.libman.model;

public class Item2 {
    private final int id;
    private final String itemCode;
    private final String location;
    private final String itemStatus;

    public Item2(int id, String itemCode, String location, String itemStatus) {
        this.id = id;
        this.itemCode = itemCode;
        this.location = location;
        this.itemStatus = itemStatus;
    }

    public int getId() {
        return id;
    }

    public String getItemCode() {
        return itemCode;
    }

    public String getLocation() {
        return location;
    }

    public String getItemStatus() {
        return itemStatus;
    }
}
