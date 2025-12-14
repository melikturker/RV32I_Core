CXX = g++
CXXFLAGS = -std=c++11 -Wall -O2
LDFLAGS = -lSDL2 -lrt

TARGET = virtual_screen
SRCS = main.cpp

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) $(SRCS) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)
