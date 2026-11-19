package vn.edu.ptit.libman.model;

import java.time.LocalDate;
import java.util.ArrayList;

public class LoanDetail2 {
    private final int id;
    private final LocalDate dueDate;
    private final Item2 item;
    private final ArrayList<Fine2> fines;

    public LoanDetail2(int id, LocalDate dueDate, Item2 item, ArrayList<Fine2> fines) {
        this.id = id;
        this.dueDate = dueDate;
        this.item = item;
        this.fines = new ArrayList<>(fines);
    }

    public int getId() {
        return id;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public Item2 getItem() {
        return item;
    }

    public ArrayList<Fine2> getFines() {
        return new ArrayList<>(fines);
    }
}
