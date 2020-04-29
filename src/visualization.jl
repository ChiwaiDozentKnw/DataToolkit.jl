function printdf(df::AbstractDataFrame)
    body!(Blink.Window(), showtable(df))
end

# run(`ubuntu run "cat /mnt/c/users/user/test.csv | clickhouse-client --input_format_defaults_for_omitted_fields=1 --format_csv_delimiter=',' --query='INSERT INTO test.test FORMAT CSVWithNames'"`)