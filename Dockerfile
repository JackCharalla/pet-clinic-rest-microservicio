FROM amazoncorretto:21-alpine
WORKDIR /workspace
COPY target/spring-petclinic-rest-*.jar app.jar
EXPOSE 9966
ENTRYPOINT [ "java", "-jar", "/workspace/app.jar" ]