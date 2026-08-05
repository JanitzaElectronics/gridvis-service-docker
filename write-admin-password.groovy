import de.janitza.pasw.tools.encryption.PasswordEncryption
import java.nio.charset.StandardCharsets
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.Properties

if (args.length != 1) {
    throw new IllegalArgumentException('Expected the GridVis server.conf path')
}

def input = System.in.newReader(StandardCharsets.UTF_8.name())
def password = input.readLine()
if (password == null || password.isEmpty() || input.readLine() != null) {
    throw new IllegalArgumentException('Expected exactly one non-empty password line')
}

if (password.length() < 8 || password.length() > 20 || password.any { Character.isWhitespace((char) it) }
        || !password.any { Character.isUpperCase((char) it) }
        || !password.any { Character.isLowerCase((char) it) }
        || !password.any { Character.isDigit((char) it) }
        || !password.any { !Character.isLetterOrDigit((char) it) }) {
    throw new IllegalArgumentException('Password does not meet the GridVis password policy')
}

def configFile = new File(args[0])
def configDirectory = configFile.parentFile
if (!configDirectory.exists() && !configDirectory.mkdirs()) {
    throw new IOException("Cannot create ${configDirectory}")
}

def properties = new Properties()
if (configFile.exists()) {
    configFile.withReader(StandardCharsets.UTF_8.name()) { properties.load(it) }
}
properties.setProperty('SERVICE_ADMIN_PASSWORD', PasswordEncryption.encrypt(password))

def temporaryFile = File.createTempFile('.server.conf.', '.tmp', configDirectory)
try {
    temporaryFile.withWriter(StandardCharsets.UTF_8.name()) { properties.store(it, 'Managed by GridVis container') }
    try {
        Files.move(temporaryFile.toPath(), configFile.toPath(), StandardCopyOption.ATOMIC_MOVE,
                StandardCopyOption.REPLACE_EXISTING)
    } catch (AtomicMoveNotSupportedException ignored) {
        Files.move(temporaryFile.toPath(), configFile.toPath(), StandardCopyOption.REPLACE_EXISTING)
    }
} finally {
    Files.deleteIfExists(temporaryFile.toPath())
}
