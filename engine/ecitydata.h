#ifndef ECITYDATA_H
#define ECITYDATA_H

#include <string>
#include <vector>

enum class eImmigrationLimitedBy;
enum class eTaxRate;

// The verdicts of the SDL side panel's data pages (overview, population, employment, husbandry, hygiene and safety, culture,
// science, appeal, military, mythology): which native string (group, string) a value reads as and how serious it is
// (0 good, 1 needs an eye, 2 trouble). The SDL pages and the Godot city window both ask here, so the two views word a city
// alike; the thresholds are the SDL pages' own.
struct eCityVerdict {
    int fGroup = 0;
    int fString = 0;
    int fSeverity = 0;

    std::string text() const;
};

namespace eCityData {
    // The tax rates from the lowest to the highest. The enum's veryLow holds 7% and low 3% (their names follow the rates), so
    // the admin page steps through this order rather than the enum's.
    std::vector<eTaxRate> taxRatesInOrder();
    eTaxRate stepTaxRate(const eTaxRate rate, const int step);

    // Overview page (group 61).
    eCityVerdict popularity(const int popularity);
    eCityVerdict foodLevel(const int canSupport, const int population);
    eCityVerdict hygiene(const int health);
    eCityVerdict unrest(const int unrest);
    eCityVerdict finances(const int netThisYear);
    // The employment line: its title (61/115 employment good, 111 workers needed or 107 unemployment) and value.
    struct eEmploymentLine {
        int fTitle = 115;
        std::string fValue;
        int fSeverity = 0;
    };
    eEmploymentLine employment(const int vacancies, const int employable, const int unemployed);

    // Husbandry page: how far the food produced goes (group 57, far too little ... surplus).
    eCityVerdict foodOpinion(const int canSupport, const int population);
    // Hygiene and safety page (group 56).
    eCityVerdict hygieneLevel(const int health);
    eCityVerdict unrestLevel(const int unrest);
    // Population page (group 55): what limits immigration and which way people move (0 when they balance).
    int immigrationLimitText(const int vacancies, const eImmigrationLimitedBy limit);
    int peopleDirectionText(const int arrived, const int left);
    // Culture and science pages (group 58): coverage in percent, terrible ... good.
    int coverageText(const int coverage);
    // Appeal page (group 133): the name of commemorative monument `id`.
    int commemorativeText(const int id);
    // Mythology page (group 59): working, sacrificing or needs materials.
    int sanctuaryStateText(const bool finished, const bool sacrificing);
    // Military page (group 51, tooltips 68): the soldiers' button and the towers' button.
    enum class eSoldiers { none, allCalled, atPalace };
    // Companies in the city (called out) and standing down at the palace; those abroad do not count.
    eSoldiers soldiers(const int inCity, const int standingDown);
    int soldiersText(const eSoldiers s);
    int soldiersTooltip(const eSoldiers s);
    int towersText(const int towers, const bool manning);
    int towersTooltip(const int towers, const bool manning);
}

#endif // ECITYDATA_H
