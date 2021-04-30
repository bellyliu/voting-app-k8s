# FROM java:7

# RUN apt-get update -qq && apt-get install -y maven && apt-get clean

# WORKDIR /code

# ADD pom.xml /code/pom.xml
# RUN ["mvn", "dependency:resolve"]
# RUN ["mvn", "verify"]

# # Adding source, compile and package into a fat jar
# ADD src /code/src
# RUN ["mvn", "package"]

# CMD ["/usr/lib/jvm/java-7-openjdk-amd64/bin/java", "-jar", "target/worker-jar-with-dependencies.jar"]

# FIXED DOCKERFILE
FROM maven:3.6-jdk-8 as build

WORKDIR /code

ADD pom.xml /code/pom.xml
RUN ["mvn", "dependency:resolve"]
RUN ["mvn", "verify"]

ADD src /code/src
RUN ["mvn", "package"]

FROM java:7

WORKDIR /app

COPY --from=build /code/target/*.jar /app/

CMD ["/usr/lib/jvm/java-7-openjdk-amd64/bin/java", "-jar", "worker-jar-with-dependencies.jar"]

