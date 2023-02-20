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

Thread.start {
    //noinspection GroovyInfiniteLoopStatement
    while(true) {
        try {
            Thread.sleep(60000)
            ProjectTools.minuteJob()
        } catch (e) {
            e.printStackTrace()
        }
    }
}