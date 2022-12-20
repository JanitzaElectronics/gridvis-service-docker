/*
 *  Copyright (c) 2014 Janitza electronics GmbH
 */
package csv;

import java.io.File;
import org.immutables.value.Value;
import org.netbeans.api.project.Project;

/**
 *
 * @author andreas.kraft
 */
@Value.Immutable
public interface IDeviceListImportParameters {

    Project getProject();

    File getImportFile();

    boolean hasToSetTimeplanForAutoSync();

}
