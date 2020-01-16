FROM openjdk:11-jre-slim-stretch
LABEL authors=cits


RUN apt-get update && apt-get install -y wget gnupg2
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
  
#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary


#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION
RUN if [ -z "$CHROME_DRIVER_VERSION" ]; \
  then CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && CHROME_DRIVER_VERSION=$(wget --no-verbose -O - "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"); \
  fi \
  && echo "Using chromedriver version: "$CHROME_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver


#============================================
# CITS
#============================================
# can specify versions by CITS_VERSION
# https://github.com/CognizantQAHub/Cognizant-Intelligent-Test-Scripter/releases/download/v$CITS_TAG/cognizant-intelligent-test-scripter-$CITS_VERSION-setup.zip
#============================================  

ARG CITS_VERSION=1.4
ARG CITS_TAG=1.4_Beta
RUN echo "Using CITS version: "$CITS_VERSION \
  && wget --no-verbose -O /tmp/cits.zip https://github.com/CognizantQAHub/Cognizant-Intelligent-Test-Scripter/releases/download/v$CITS_TAG/cognizant-intelligent-test-scripter-$CITS_VERSION-setup.zip \
  && rm -rf /opt/cits \
  && unzip /tmp/cits.zip -d /opt \
  && rm /tmp/cits.zip \
  && sed -i.command '1s/^/#!\/bin\/bash\n/' /opt/cognizant-intelligent-test-scripter-$CITS_VERSION/Run.command \
  && chmod 755 /opt/cognizant-intelligent-test-scripter-$CITS_VERSION/Run.command \
  && echo '#!/bin/bash' > /usr/bin/cits \
  && echo './opt/cognizant-intelligent-test-scripter-$CITS_VERSION/Run.command "$@"' >> /usr/bin/cits \
  && chmod 755 /usr/bin/cits \
  && cits -version
 