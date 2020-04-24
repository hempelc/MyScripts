# coding=UTF-8

# Converts a csv table with station, date, property, sign, value to
# rows with station, date and all values

import sys

class station:
    """A station at a spec. date with all collected data"""
    def __init__(self, name, date):
        self.name = name
        self.dates = {date:{}}

    def addValue(self, date, propName, value):
        if not date in self.dates:
            self.dates[date] = {}
        self.dates[date][propName] = value


    def calcContaminationSummaries(self, date):
        limits = {"TotalPAH":1607.0, "TotalPCB":24.6,
                  "Zn":249.0, "Pb":78.0, "Hg":0.53, "Cd":1.0, "Cr":39.0,
                  "Cu":55.0, "Ni":23.0, "%MO":2.0} # POT not used!

        
        dateData = self.dates[date]
        totalPCB = 0.0
        totalPAH = 0.0
        totalHCH = 0.0
        totalDDT = 0.0
        for key in dateData:
            if key[0:3] == "3PA":
                totalPAH += float(dateData[key])
            elif key[0:2] == "1C":
                totalPCB += float(dateData[key])
            elif key[0:3] == "2DD":
                totalDDT += float(dateData[key])
            elif key[1:4] == "HCH":
                totalHCH += float(dateData[key])

        self.addValue(date, "TotalPAH", totalPAH)
        self.addValue(date, "TotalPCB", totalPCB)
        self.addValue(date, "TotalHCH", totalHCH)
        self.addValue(date, "TotalDDT", totalDDT)

        piComps = []
        for piKey in limits:
            if piKey in dateData:
                piComp = 0.0
                val = float(dateData[piKey])
                geo =  [0,0.5,1,2,4,8]
                for i in range(1,len(geo)):
                    f=geo[i]
                    if val<limits[piKey]*f:
                        piComp += (val-limits[piKey]*geo[i-1])/(limits[piKey]*f-limits[piKey]*geo[i-1])
                        break
                    else:
                        piComp += 1.0
                piComps.append(piComp)
        if piComps:
            self.addValue(date, "PI", sum(piComps)/len(piComps))


    def getDateData(self, date):
        return self.dates[date]
        

def main():


    # Read metadata
    
    stations = {}
    propNames = []
    
    md = open(sys.argv[1],"r")
    firstLine = True
    for line in md:
        if firstLine:
            firstLine = False
        else:
            items = line[:-1].split("\t")
            st = items[0]
            date = items[1]
            propName = items[2]
            sign = items[3]
            value = items[4]

            if sign == "<":
                value = "0" #str(float(value)/2)
                # Detection limits change 2013 -- 2018 and often are higher than detected
                # postivie values later on, causing a mess. Plus unusual things with high
                # detection limit is added beloning to total PCB or PAH causing increase

            if propName in ["Pb","Ni","CuT","Hg","Cr6","Crt","Cd","As",
                            "Zn","Cu","Co","Se","Sn","Ba","Bo","Be",
                            "Sb","Mo","Sr","Cr"] and items[5][:3] == "µg":
                value = str(float(value)/1000)

            if not st in stations:
                stations[st] = station(name = st, date=date)
            stations[st].addValue(date=date, propName=propName, value=value)

            if not propName in propNames:
                propNames.append(propName)

    md.close()

    # Calculate total PCB and PAH

    propNames+=["TotalPCB", "TotalPAH", "TotalDDT", "TotalHCH", "PI"]
    
    for sn in stations:
        st = stations[sn]
        for date in st.dates:
            st.calcContaminationSummaries(date)
            
    
    # Print data

    print "\t".join(["Station", "Date"] + propNames)

    for sn in stations:
        st = stations[sn]
        for date in st.dates:
            pl = [st.name, date]
            dd = st.getDateData(date)

            #print "DEBUG %s %s" % (st.name, date)
            #print "DEBUG %s" % dd
            
            for pn in propNames:
                if pn in dd:
                    pl.append(dd[pn])
                    #print "DEBUG %s : %s" % (pn, dd[pn])
                else:
                    pl.append("NA")
                    #print "DEBUG %s : NA" % pn
            print "\t".join(str(f) for f in pl)

        
    
if __name__ == "__main__":

    main()
    
