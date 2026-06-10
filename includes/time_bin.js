function time_bin(col) {
    return `CASE
        WHEN ${col} >= 4  AND ${col} < 8  THEN 'Early_Morning'
        WHEN ${col} >= 8  AND ${col} < 12 THEN 'Morning'
        WHEN ${col} >= 12 AND ${col} < 16 THEN 'Afternoon'
        WHEN ${col} >= 16 AND ${col} < 20 THEN 'Evening'
        WHEN ${col} >= 20 AND ${col} < 24 THEN 'Night'
        ELSE 'Late_Night'
    END`;
}
module.exports = time_bin;
