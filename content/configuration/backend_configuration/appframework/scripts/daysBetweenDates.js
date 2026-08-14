function daysBetweenDates(earlierDate, laterDate) {
    // A day in UTC always lasts 24 hours
    const ONE_DAY_MS = 1000 * 60 * 60 * 24;
    var d1 = new Date(earlierDate);
    var d2 = new Date(laterDate);
    // Convert dates to UTC timestamps at midnight to ignore local time
    const start = Date.UTC(d1.getFullYear(), d1.getMonth(), d1.getDate());
    const end = Date.UTC(d2.getFullYear(), d2.getMonth(), d2.getDate());

    // Calculate the absolute difference in milliseconds and convert to days
    const differenceMs = end - start;
    return Math.floor(differenceMs / ONE_DAY_MS);
}