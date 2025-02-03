CXX := clang -framework ApplicationServices
CXXFLAGS := -g -Og -Wall -Iinclude
DEPFLAGS := -MMD -MP  # Generates .d files with dependencies

# Directories
SRCDIR := src
INCDIR := include
BINDIR := bin

# Target binary
TARGET := $(BINDIR)/app

# Source and object files
SOURCES := $(shell find $(SRCDIR) -type f -name '*.c')
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(BINDIR)/%.o)
DEPFILES := $(OBJECTS:.o=.d)  # Dependency files

# Default rule
all: $(TARGET)

# Linking
$(TARGET): $(OBJECTS)
	@echo $(SOURCES)
	@mkdir -p $(BINDIR)
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@

# Compiling
$(BINDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(shell dirname $@)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

# Include dependency files
-include $(DEPFILES)

clean:
	rm -rf $(BINDIR)

# Phony targets
.PHONY: all clean
