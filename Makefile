PROJECT  := builder
DEPENDS  :=
OPTIONS  :=
SOURCES  := src/

CC       := gcc
CFLAGS   := -Wall -std=c99
CXX      := g++
CXXFLAGS := -Wall
AR       := ar
ARFLAGS  := rv
LD       := $(CC)
LDFLAGS  :=
LDLIBS   :=

RM       := rm -rf
MKDIR    := mkdir -p
QUIET    :=

OUTPUT   :=

# edition
LANGUAGE := English
EDITION  := Professional

HOST     := linux
PLATFORM :=

##############################################################################
define import
    ifneq ($(1),$(PROJECT))
        projects := $(projects) $(filter-out $(projects),$(PROJECT))

        $(1)-depends := $($(1)-depends) $(PROJECT)

        $(PROJECT)-targets := $(addprefix $(2),$(PROJECT))
        $(PROJECT)-depends := $(DEPENDS)
        $(PROJECT)-options := $(OPTIONS)
        $(PROJECT)-ar      := $(AR)
        $(PROJECT)-arflags := $(ARFLAGS)
        $(PROJECT)-ld      := $(LD)
        $(PROJECT)-ldlibs  := $(LDLIBS)
        $(PROJECT)-ldflags := $(LDFLAGS)
    endif

    $(PROJECT)-sources := $($(PROJECT)-sources) \
        $(addprefix $(2), $(filter-out %/, $(SOURCES)))

    $(2)-cc       := $(CC)
    $(2)-cflags   := $(CFLAGS)
    $(2)-cxx      := $(CXX)
    $(2)-cxxflags := $(CXXFLAGS)

    $$(foreach dir, $(filter %/, $(SOURCES)),           \
        $$(eval PROJECT  := $(PROJECT))                 \
        $$(eval DEPENDS  :=)                            \
        $$(eval OPTIONS  :=)                            \
        $$(eval SOURCES  :=)                            \
        $$(eval AR       := $(AR))                      \
        $$(eval ARFLAGS  := $(ARFLAGS))                 \
        $$(eval LD       := $(LD))                      \
        $$(eval LDLIBS   :=)                            \
        $$(eval LDFLAGS  := $(LDFLAGS))                 \
        $$(eval CC       := $(CC))                      \
        $$(eval CFLAGS   := $(CFLAGS))                  \
        $$(eval CXX      := $(CXX))                     \
        $$(eval CXXFLAGS := $(CXXFLAGS))                \
        $$(eval include $(2)$$(dir)Makefile)            \
        $$(eval $$(call import,$(PROJECT),$(2)$$(dir))) \
    )
endef
##############################################################################

$(eval $(call import))

##############################################################################
# program.
all: $(-depends)

##############################################################################
# sources.
sources := $(foreach project, $(projects), $($(project)-sources))

# depends.
$(foreach project, $(projects),                                        \
    $(eval $($(project)-targets):                                      \
	$(foreach depend, $($(project)-depends), $($(depend)-targets)) \
    )                                                                  \
)

# objects
$(foreach project, $(projects),                                    \
    $(eval $(project)-objects :=                                   \
        $(patsubst %.c,%.o, $(filter %.c, $($(project)-sources)))  \
        $(patsubst %.cc,%.o,$(filter %.cc,$($(project)-sources)))) \
)

# c sources and object.
c-sources := $(filter %.c, $(sources))
c-objects := $(patsubst %.c, %.o, $(c-sources))
$(c-objects): %.o: %.c
	$(strip                                        \
            $(QUIET)                                   \
            $($(patsubst %$(notdir $<),%,$<)-cc)       \
            $($(patsubst %$(notdir $<),%,$<)-cflags)   \
            -c -o $@ $<)

# cxx sources and object.
cxx-sources := $(filter %.cc, $(sources))
cxx-objects := $(patsubst %.cc, %.o, $(cxx-sources))
$(cxx-objects): %.o: %.cc
	$(strip                                        \
            $(QUIET)                                   \
            $($(patsubst %$(notdir $<),%,$<)-cxx)      \
            $($(patsubst %$(notdir $<),%,$<)-cxxflags) \
            -c -o $@ $<)

# program.
$(foreach program, $(filter-out lib%.a lib%.so, $(projects)), \
    $(if $(filter module,$($(program)-options)),              \
        $(eval .PHONY: $($(program)-targets))                 \
        $(eval $($(program)-targets): $($(program)-objects))  \
        ,                                                     \
        $(eval $($(program)-targets): $($(program)-objects);  \
            $(strip                                           \
                $(QUIET)                                      \
                $($(program)-ld) $($(program)-ldflags) -o     \
                $($(program)-targets) $($(program)-objects)   \
                $($(program)-ldlibs)                          \
            )                                                 \
        )                                                     \
    )                                                         \
)

# shared library.
$(foreach library, $(filter lib%.so, $(projects)),            \
    $(eval $($(library)-targets): $($(library)-objects);      \
        $(strip                                               \
            $(QUIET)                                          \
            $($(library)-ld) $($(library)-ldflags) -shared -o \
            $($(library)-targets) $($(library)-objects)       \
            $($(library)-ldlibs)                              \
        )                                                     \
    )                                                         \
)


# staic library.
$(foreach library, $(filter lib%.a, $(projects)),             \
    $(eval $($(library)-targets): $($(library)-objects);      \
        $(strip                                               \
            $(QUIET)                                          \
            $($(library)-ar) $($(library)-arflags)            \
            $($(library)-targets) $($(library)-objects)       \
        )                                                     \
    )                                                         \
)

##############################################################################

.PHONY: all clean package
clean:
	$(strip $(RM) $(c-objects) $(cxx-objects))
