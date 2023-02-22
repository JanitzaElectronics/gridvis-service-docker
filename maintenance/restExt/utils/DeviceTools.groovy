package utils

import org.openide.util.Lookup;
import de.janitza.pasw.database.IDBDeviceManager;
import de.janitza.pasw.database.IDeviceSyncService;
import de.janitza.pasw.device.core.api.marker.ISubmoduleDevice;
import de.janitza.pasw.project.api.IProjectListProvider
import java.util.function.Consumer


class DeviceTools {
    static syncDevices() {
        def projName = ProjectTools.getProjectName();
        Lookup.getDefault().lookup(IProjectListProvider).forName(projName).ifPresent({ p ->
            def devManager = p.getLookup().lookup(IDBDeviceManager);
            def dsService = p.getLookup().lookup(IDeviceSyncService.class);
            devManager.getDevices().stream()
                    .filter { it.getDevice().getLookup().lookup(ISubmoduleDevice.class) == null }
                    .filter {System.currentTimeMillis() - it.getLastSynced() / 1000000 > 900000 } // older 15 Minutes
                    .each {
                        dsService.addDevice(it);
                        println("Syncing device ${it.getDeviceId()} - ${System.currentTimeMillis() - it.getLastSynced() / 1000000}")
                    }
        } as Consumer)

    }
}
