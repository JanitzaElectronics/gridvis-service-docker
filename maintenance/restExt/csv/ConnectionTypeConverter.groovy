/*
 * ConnectionTypeConverter.java
 *
 * Copyright (c) 2011 Janitza electronics GmbH
 */
package csv;

import de.janitza.pasw.device.core.connection.api.connectiontype.ConnectionTypes;
import java.util.Collections;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 *
 * @author andreas.kraft
 */
public final class ConnectionTypeConverter {

    private static final Map<String, String> MAP;

    static {
        final Map<String, String> map = new HashMap<String, String>();
        for (final ConnectionTypes connType : ConnectionTypes.values()) {
            insertAssociation(map, connType.getID(), connType.getIdForCSVExport());
        }
        MAP = Collections.unmodifiableMap(map);
    }

    /**
     * Creates a new instance of ConnectionTypeConverter
     */
    private ConnectionTypeConverter() {
    }

    private static void insertAssociation(final Map<String, String> map,
                                          final String pasw, final String csv) {
        final String csvUpper = csv.toUpperCase(Locale.getDefault());
        map.put(csvUpper, pasw);
        map.put(pasw, csvUpper);
    }

    /**
     * Convert ConnectionType-String as used in csv-export to internally usable string.
     *
     * @param csv
     * @return
     */
    public static String convertCSVToPASW(final String csv) {
        return MAP.get(csv.toUpperCase(Locale.getDefault()));
    }

    /**
     * Convert ConnectionType-String as used internally to string usable in csv-export
     *
     * @param pasw
     * @return
     */
    public static String convertPASWtoCSV(final String pasw) {
        return MAP.get(pasw);
    }
}
