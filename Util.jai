tcprint :: (format_string: string, args: .. Any) -> *u8 {
    tstr := tprint(format_string, ..args);
    result : *u8 = temporary_alloc(size_of(u8) * (tstr.count+1));
    memcpy(result, tstr.data, tstr.count);
    result[tstr.count] = 0;
    return result;
}

get_enum_count :: ($enum_type : Type) -> s64 {
    info := type_info(enum_type);
    assert(info.type == Type_Info_Tag.ENUM);
    info_enum := cast(*Type_Info_Enum) info;
    return info_enum.values.count;
}

get_enum_max :: inline ($enum_type: Type) -> s64 {
    return get_enum_count(enum_type) - 1;
}

draw_axis :: (position: Vector3, color: Color) {
    SIZE :: 0.25;
    DrawLine3D(position-.{SIZE,0,0}, position+.{SIZE,0,0}, color);
    DrawLine3D(position-.{0,SIZE,0}, position+.{0,SIZE,0}, color);
    DrawLine3D(position-.{0,0,SIZE}, position+.{0,0,SIZE}, color);
}
