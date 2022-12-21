import csv.CSV
import csv.IDeviceListImportParameters
import csv.ImportInformation
import de.janitza.pasw.device.core.api.IDeviceManager
import org.netbeans.api.project.Project
import utils.ProjectTools

if(!ProjectTools.checkProjectDir()) {
    def dbType = System.getenv('DB_TYPE') ?: 'jandb'
    if('jandb'.equals(dbType)) {
        ProjectTools.createJanDBProject()
    } else if('mariadb'.equals(dbType)) {
        ProjectTools.createMySQLProject()
    } else if('mssql'.equals(dbType)) {
        ProjectTools.createMSSQLProject()
    }
}

class ImportParameter implements IDeviceListImportParameters {

    Project getProject() {
        return ProjectTools.getProject()
    }

    File getImportFile() {
        new File("/opt/GridVisData/devices.csv")
    }

    boolean hasToSetTimeplanForAutoSync() {
        return false
    }
}

Thread.start {
    //noinspection GroovyInfiniteLoopStatement
    while(true) {
        try {
            Thread.sleep(60000)
            ProjectTools.minuteJob()
            if(ProjectTools.getProject() != null && new File("/opt/GridVisData/devices.csv").exists()) {
                System.out.println("Device Import")
                def importInfo = new ImportInformation()
                final List<IDeviceManager.AddDeviceHelper> existingDevices = new ArrayList<>()
                final List<IDeviceManager.AddDeviceHelper> addedDevices = new ArrayList<>()
                CSV.importDevices(new ImportParameter(), false, importInfo, addedDevices, existingDevices)
                println("Imported: " + importInfo.numberImportedDevices)
                println("Skipped: " + importInfo.numberSkippedDevices)
            }
        } catch (e) {
            e.printStackTrace()
        }
    }
}