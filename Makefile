
include CONFIG

MATH = $(patsubst %.cpp,%.o,$(wildcard Math/*.cpp))

TOOLS = $(patsubst %.cpp,%.o,$(wildcard Tools/*.cpp))

NETWORK = $(patsubst %.cpp,%.o,$(wildcard Networking/*.cpp))

PROCESSOR = $(patsubst %.cpp,%.o,$(wildcard Processor/*.cpp))

#FHEOBJS = $(patsubst %.cpp,%.o,$(wildcard FHEOffline/*.cpp FHE/*.cpp)) Protocols/CowGearOptions.o

GC = $(patsubst %.cpp,%.o,$(wildcard GC/*.cpp)) $(PROCESSOR)
GC_SEMI = GC/SemiSecret.o GC/SemiPrep.o GC/square64.o

COMMONOBJS = $(MATH) $(TOOLS) $(NETWORK) GC/square64.o Processor/OnlineOptions.o Processor/BaseMachine.o Processor/DataPositions.o Processor/ThreadQueues.o Processor/ThreadQueue.o
#COMPLETE = $(COMMON) $(PROCESSOR) $(FHEOFFLINE) $(TINYOTOFFLINE) $(GC) $(OT)
COMPLETE = $(COMMON) $(PROCESSOR) $(GC)
VMOBJS = $(PROCESSOR) $(COMMONOBJS) GC/square64.o GC/Instruction.o OT/OTTripleSetup.o OT/BaseOT.o $(LIBSIMPLEOT)
VM = $(SHAREDLIB)
COMMON = $(SHAREDLIB)

LIB = libSPDZ.a
SHAREDLIB = /usr/local/lib/libSPDZ.so
FHEOFFLINE = libFHE.so
LIBRELEASE = librelease.a

# used for dependency generation
#OBJS = $(BMR) $(FHEOBJS) $(TINYOTOFFLINE) $(YAO) $(COMPLETE) $(patsubst %.cpp,%.o,$(wildcard Machines/*.cpp Utils/*.cpp))
OBJS = $(COMPLETE) $(patsubst %.cpp,%.o,$(wildcard Machines/*.cpp Utils/*.cpp))
DEPS := $(wildcard */*.d */*/*.d)

# never delete
.SECONDARY: $(OBJS) $(patsubst %.cpp,%.o,$(wildcard */*.cpp))


all: arithmetic binary gen_input online offline externalIO bmr ecdsa
vm: arithmetic binary

.PHONY: doc
doc:
	cd doc; $(MAKE) html

arithmetic: rep-ring rep-field shamir semi2k-party.x semi-party.x mascot sy
binary: rep-bin yao semi-bin-party.x tinier-party.x tiny-party.x ccd-party.x malicious-ccd-party.x real-bmr

all: overdrive she-offline
arithmetic: hemi-party.x soho-party.x gear

-include $(DEPS)
include $(wildcard *.d static/*.d)

%.o: %.cpp
	$(CXX) -o $@ $< $(CFLAGS) -MMD -MP -c

online: Fake-Offline.x Server.x Player-Online.x Check-Offline.x emulate.x

offline: $(OT_EXE) Check-Offline.x mascot-offline.x cowgear-offline.x mal-shamir-offline.x

shamir: shamir-party.x malicious-shamir-party.x atlas-party.x galois-degree.x

$(LIBRELEASE): Protocols/MalRepRingOptions.o $(PROCESSOR) $(COMMONOBJS) $(TINIER) $(GC)
	$(AR) -csr $@ $^

CFLAGS += -fPIC
LDLIBS += -Wl,-rpath -Wl,/usr

$(SHAREDLIB): $(PROCESSOR) $(COMMONOBJS) GC/square64.o GC/Instruction.o
	$(CXX) $(CFLAGS) -shared -o $@ $^ $(LDLIBS)

#$(FHEOFFLINE): $(FHEOBJS) $(SHAREDLIB)
#	$(CXX) $(CFLAGS) -shared -o $@ $^ $(LDLIBS)
#
galois-degree.x: Utils/galois-degree.o
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

%.x: Utils/%.o $(COMMON)
	$(CXX) -o $@ $(CFLAGS) $^ $(LDLIBS)

%.x: Machines/%.o $(SHAREDLIB)
	$(CXX) -o $@ $(CFLAGS) $^ $(LDLIBS)

# random shamir preproc
random-shamir.x: $(VM) $(shamir)

clean:
	-rm -f */*.o *.o */*.d *.d *.x core.* *.a gmon.out */*/*.o static/*.x *.so
