# DependencyCheck Central Database Docker

Docker-based self-updating central [OWASP DependencyCheck](https://www.owasp.org/index.php/OWASP_Dependency_Check) Database Server.
This is an out-of-the-box solution for the central Enterprise Setup described [here](https://jeremylong.github.io/DependencyCheck/data/database.html). It is based on a [MySQL](https://hub.docker.com/_/mysql/) database.

## Benefits
- Very fast analysis
- Self-updating, thus always up-to-date CVE data
- No manual central database setup required
- Analysis clients do not require internet access (see below)
- Improved reliability in case of connection issues to the NVD


## Setup

### Central Database Server

In order to start the Database Server simply run
```bash
docker run -p 3306:3306 stefanneuhaus/dependencycheck-central-mysql
```

#### NVD API key

To have a faster synchronization process, you should apply for an NVD API key.
Get one [at the NVD website](https://nvd.nist.gov/developers/request-an-api-key).
If you have one, start your Docker container with `-e NVD_API_KEY=<Your API key here>`.

### Analysis Clients

All kinds of analysis clients are supported: Gradle, Maven, Ant, Jenkins, CLI. Apply the following changes to your build file:
- add buildscript dependency for `com.mysql:mysql-connector-j`
- disable database updates triggered by your project: `autoUpdate = false`
- add database connection parameters: `data { ... }`

Example (Gradle):
```groovy
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'org.owasp:dependency-check-gradle:10.0.2'
        classpath 'com.mysql:mysql-connector-j:8.4.0'
    }
}

apply plugin: 'org.owasp.dependencycheck'

dependencyCheck {
    autoUpdate = false
    data {
        connectionString = "jdbc:mysql://<DC_HOST>:3306/dependencycheck?useSSL=false&allowPublicKeyRetrieval=true"
        driver = "com.mysql.cj.jdbc.Driver"
        username = "dc"
        password = "dc"
    }
}
```

Start the Dependency Analysis:
```bash
./gradlew dependencyCheckAnalyze
```


## Database Updates

Updates of the Database are triggered every 2 minutes. The initial update can take quite some time (~50 min on my machine). In order to get reliable analysis results the initial update must have finished successfully. Subsequent updates are incremental ones and should finish within a couple of seconds.


## Compatibility

|             Client |   Server |
|-------------------:|---------:|
|         `>= 6.3.0` | `10.0.2` |
|         `>= 6.3.0` |  `9.0.8` |
|         `>= 6.3.0` |  `8.0.0` |
|         `>= 6.3.0` |  `7.4.4` |
|   `[6.3.0; 7.4.3]` |  `6.5.3` |
|   `[6.1.3; 6.2.2]` |  `6.2.0` |
|   `[6.0.0; 6.1.1]` |  `6.0.2` |
| `[5.0.0; 5.3.2.1]` |  `5.0.0` |
|   `[1.4.1; 4.0.2]` |  `4.0.2` |
|          `< 1.4.1` |     n.a. |

The server is not designed for updating its database structure manually. If you update your client to a version which is incompatible with your server version, 
you should just throw away the old server container and start a new one from a compatible image from scratch.

* _Client_: DependencyCheck used in your project to be analyzed
* _Server_: the dependencycheck-central-mysql-docker container


## Notes

- Clients do not require internet access in general. There are only a few analyzers that do require it. Please refer to the [OWASP DependencyCheck documentation](https://jeremylong.github.io/DependencyCheck/data/index.html#Downloading_Additional_Information) for further information.
- Running the image as non-root: use the mysql(999:999) user provided by the base image (mysql).
