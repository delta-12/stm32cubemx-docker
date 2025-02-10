# Install STM32CubeMX
FROM debian:stable-slim AS cube-install
RUN apt update
RUN apt install -y unzip
WORKDIR /STM32CubeMX
COPY en.stm32cubemx-lin-v6-13-0.zip en.stm32cubemx-lin-v6-13-0.zip
COPY auto-install.xml auto-install.xml
RUN unzip en.stm32cubemx-lin-v6-13-0.zip
RUN ./SetupSTM32CubeMX-6.13.0 auto-install.xml

# Copy STM32CubeMX to image with graphical dependencies
FROM debian:stable-slim AS cube-initialize
RUN apt update
RUN apt install -y xvfb libgtk-3-dev fonts-dejavu libasound2 libnss3 libnspr4
COPY --from=cube-install /opt/STM32CubeMX /opt/STM32CubeMX
ENV DISPLAY=:10
RUN echo "#!/bin/sh" > /script
RUN echo "Xvfb :10 -ac > /dev/null &" >> /script
RUN echo "\"\$@\"" >> /script
RUN chmod +x /script

# Initialize STM32CubeMX
WORKDIR /root
RUN echo "exit" > init.script
RUN /script /opt/STM32CubeMX/jre/bin/java -jar /opt/STM32CubeMX/STM32CubeMX -q init.script
RUN rm init.script

# Copy initialized STM32CubeMX to clean image
FROM debian:stable-slim AS cube-clean
RUN apt update
RUN apt install -y xvfb libgtk-3-dev fonts-dejavu libasound2 libnss3 libnspr4
ENV DISPLAY=:10
COPY --from=cube-initialize /opt/STM32CubeMX /opt/STM32CubeMX
COPY --from=cube-initialize /script /script
COPY --from=cube-initialize /root /root

# Cleanup
WORKDIR /root
RUN apt clean
RUN rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Start Xvfb display
ENTRYPOINT ["/script"]
