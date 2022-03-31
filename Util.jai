tcprint :: (format_string: string, args: .. Any) -> *u8 {
    tstr := tprint(format_string, ..args);
    result : *u8 = temporary_alloc(size_of(u8) * (tstr.count+1));
    memcpy(result, tstr.data, tstr.count);
    result[tstr.count] = 0;
    return result;
}
