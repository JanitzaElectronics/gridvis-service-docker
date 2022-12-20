/*
 * ImportInformation.java
 * 
 * Copyright (c) 2011 Janitza electronics GmbH
 */

package csv;

/**
 *
 * @author waldemar.huck
 */
public class ImportInformation {
    private int m_ImportedDevices = 0;
    private int m_SkippedDevices = 0;

    /**
     * Constructs
     */
    public ImportInformation() {}

    public void setNumberImportedDevices(final int numImported) {
        this.m_ImportedDevices = numImported;
    }

    public void setNumberSkippedDevices(final int numSkipped) {
        this.m_SkippedDevices = numSkipped;
    }

    public int getNumberImportedDevices() {
        return m_ImportedDevices;
    }

    public int getNumberSkippedDevices() {
        return m_SkippedDevices;
    }

    public void incSkippedDevices() {
        m_SkippedDevices++;
    }
}
