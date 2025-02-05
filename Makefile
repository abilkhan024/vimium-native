CXX := clang # -DVERBOSE_LOG
CXXFLAGS := -g -Og -Wno-unused-command-line-argument -Wall -Iinclude -I/
LDFLAGS := -framework ApplicationServices -framework Cocoa -framework Foundation # -Llib -lSDL2 -lSDL2_ttf

DEPFLAGS := -MMD -MP

# Directories
SRCDIR := src
INCDIR := include
BINDIR := bin

# Target binary
TARGET := $(BINDIR)/app

# Source and object files
SOURCES := $(shell find $(SRCDIR) -type f | grep -e '\.c\|m')
OBJECTS := $(patsubst $(SRCDIR)/%.c, $(BINDIR)/%.o, $(SOURCES))
OBJECTS := $(patsubst $(SRCDIR)/%.m, $(BINDIR)/%.o, $(OBJECTS))

DEPFILES := $(OBJECTS:.o=.d)  # Dependency files

# Default rule
all: $(TARGET)

# Linking
$(TARGET): $(OBJECTS)
	@echo $(SOURCES)
	@mkdir -p $(BINDIR)
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@

$(BINDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CXX) -c $< -o $@ $(CXXFLAGS)

# Compiling .m files
$(BINDIR)/%.o: $(SRCDIR)/%.m
	@mkdir -p $(shell dirname $@)
	$(CXX) -c $< -o $@ $(CXXFLAGS) $(LDFLAGS) 

# Include dependency files
-include $(DEPFILES)

clean:
	rm -rf $(BINDIR)

# Phony targets
.PHONY: all clean
