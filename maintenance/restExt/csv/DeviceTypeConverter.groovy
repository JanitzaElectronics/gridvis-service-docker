/*
 * DeviceTypeConverter.java
 * 
 * Copyright (c) 2011 Janitza electronics GmbH
 */

package csv;

import de.janitza.pasw.device.core.api.IDevicetypeNamesConverter;

import org.openide.util.Lookup;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

/**
 * Class for converting device type names.
 * @author andreas.kraft
 */
public final class DeviceTypeConverter {

    /** Creates a new instance of DeviceTypeConverter */
    private DeviceTypeConverter() {}

    /**
     * converts device type name from csv import to internal device type name.
     * @param csv csv type name.
     * @return
     */
    public static String convertCSVToPASW(final String csv) {
        final Collection<? extends IDevicetypeNamesConverter> lookupAll =
            Lookup.getDefault().lookupAll(IDevicetypeNamesConverter.class);
        final Map<String, String> map = new HashMap<>(lookupAll.size());
        for(final IDevicetypeNamesConverter converter : lookupAll) {
            map.put(converter.getCSVName(), converter.getInternalName());
        }

        return map.get(csv);
    }

    /**
     * converts internal device type name to name for csv export.
     * @param pasw internal type name
     * @return
     */
    public static String convertPASWtoCSV(final String pasw) {
        final Collection<? extends IDevicetypeNamesConverter> lookupAll =
            Lookup.getDefault().lookupAll(IDevicetypeNamesConverter.class);
        final Map<String, String> map = new HashMap<>(lookupAll.size());
        for(final IDevicetypeNamesConverter converter : lookupAll) {
            map.put(converter.getInternalName(), converter.getCSVName());
        }

        return map.get(pasw);
    }

    /**
     *
     * @param devinfoname
     * @return
     */
    public static String convertDevinfoToPASW(final String devinfoname) {
        final Collection<? extends IDevicetypeNamesConverter> lookupAll =
            Lookup.getDefault().lookupAll(IDevicetypeNamesConverter.class);
        final Map<String, String> map = new HashMap<>(lookupAll.size());
        for(final IDevicetypeNamesConverter converter : lookupAll) {
            map.put(converter.getUniqueTypeName(), converter.getInternalName());
        }

        return map.get(devinfoname);
    }

    public static String convertPASWtoDevinfo(final String pasw) {
        final Collection<? extends IDevicetypeNamesConverter> lookupAll =
            Lookup.getDefault().lookupAll(IDevicetypeNamesConverter.class);
        final Map<String, String> map = new HashMap<>(lookupAll.size());
        for(final IDevicetypeNamesConverter converter : lookupAll) {
            map.put(converter.getInternalName(), converter.getUniqueTypeName());
        }

        return map.get(pasw);
    }
}
