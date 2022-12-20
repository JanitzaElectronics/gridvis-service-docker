/*
 *  Copyright (c) 2014 Janitza electronics GmbH
 */
package csv;

import de.janitza.pasw.device.core.api.IDeviceCreator;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.openide.cookies.InstanceCookie;
import org.openide.filesystems.FileObject;
import org.openide.filesystems.FileUtil;
import org.openide.loaders.DataObject;

/**
 *
 * @author andreas.kraft
 */
public class DeviceCreatorMap {

    private static final DeviceCreatorMap INSTANCE = new DeviceCreatorMap();

    private final Map<String, IDeviceCreator> m_DeviceCreatorMap;

    /**
     * creates new instance
     */
    private DeviceCreatorMap() {
        m_DeviceCreatorMap = createDeviceConvertMap();
    }

    private static Map<String, IDeviceCreator> createDeviceConvertMap() {
        final Map<String, IDeviceCreator> convertMap = new HashMap<>();
        final FileObject configFile = FileUtil.getConfigFile("Devices/Modules");

        if (configFile != null) {
            final FileObject[] children =
                    configFile.getChildren();
            for (final FileObject fo : children) {
                try {
                    final InstanceCookie cookie =
                            DataObject.find(fo).getCookie(InstanceCookie.class);
                    final IDeviceCreator creator = (IDeviceCreator) cookie
                            .instanceCreate();
                    convertMap.put(fo.getAttribute("Type").toString(), creator);
                } catch (final ClassNotFoundException | IOException ex) {
                    Logger.getLogger(DeviceCreatorMap.class.getName())
                            .log(Level.WARNING,
                                 "error creating map for IDeviceCreator", ex);
                }
            }
        }
        return convertMap;
    }

    /**
     * Return instance of IDeviceCreator
     *
     * @param devTypeFromDevInfo Device type as defined by
     * IDeviceInformation::getUniqueName
     * @return IDeviceCreator for device type
     */
    public IDeviceCreator getDeviceCreatorByDeviceInfo(final String devTypeFromDevInfo) {
        final String deviceType =
                DeviceTypeConverter.convertDevinfoToPASW(devTypeFromDevInfo);
        return m_DeviceCreatorMap.get(deviceType);
    }

    /**
     * Return instance of IDeviceCreator
     *
     * @param devType Device type as defined by IDevicetypeNamesConverter::getInternalName
     * @return IDeviceCreator for device type
     */
    public IDeviceCreator getDeviceCreatorByInternalType(final String devType) {
        return m_DeviceCreatorMap.get(devType);
    }

    /**
     *
     * @return Instance
     */
    public static DeviceCreatorMap getInstance() {
        return INSTANCE;
    }
}
