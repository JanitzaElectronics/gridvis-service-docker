/*
 *  Copyright (c) 2014 Janitza electronics GmbH
 */
package csv;

import org.netbeans.api.project.Project;

/**
 *
 * @author andreas.kraft
 */
public interface IDeviceListImportParameters {

    Project getProject();

    File getImportFile();

    boolean hasToSetTimeplanForAutoSync();

}
