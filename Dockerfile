FROM amazoncorretto:21
WORKDIR /workspace
COPY target/pet-clinic-rest-microservicio-*.jar app.jar
EXPOSE 9966
ENTRYPOINT [ "java", "-jar", "/workspace/app.jar" ]