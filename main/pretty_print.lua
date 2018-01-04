local PrettyPrint do
	local isPrimitiveType = {string=true, number=true, boolean=true}

	local function isPrimitiveArray(array)
		local max,n = 0,0
		for k,v in pairs(array) do
			if not (type(k) == 'number' and k > 0 and math.floor(k) == k) or not isPrimitiveType[type(v)] then
				return false
			end
			max = k > max and k or max
			n = n + 1
		end
		return n == max
	end

	local function formatValue(value)
		if type(value) == 'string' then
			return string.format('%q',value)
		else
			return tostring(value)
		end
	end

	local function formatKey(key,seq)
		if seq then return "" end
		if type(key) == 'string' then
			if key:match('^[%a_][%w_]-$') == key then -- key is variable name
				return key .. " = "
			else
				return "[" .. string.format('%q',key) .. "] = "
			end
		else
			return "[" .. tostring(key) .. "] = "
		end
	end

	local typeSortOrder = {
		['boolean']  = 1;
		['number']   = 2;
		['string']   = 3;
		['function'] = 4;
		['thread']   = 5;
		['table']    = 6;
		['userdata'] = 7;
		['nil']      = 8;
	}

	local function traverseTable(dataTable,tableRef,indent)
		local output = ""

		local indentStr = string.rep("  ",indent)

		local keyList = {}
		for k,v in pairs(dataTable) do
			if isPrimitiveType[type(k)] then
				keyList[#keyList + 1] = k
			end
		end
		table.sort(keyList,function(a,b)
			local ta,tb = type(dataTable[a]),type(dataTable[b])
			if ta == tb then
				if type(a) == 'number' and type(b) == 'number' then
					return a < b
				else
					return tostring(a) < tostring(b)
				end
			else
				return typeSortOrder[ta] < typeSortOrder[tb]
			end
		end)

		local in_seq = false
		local prev_key = 0

		for i = 1,#keyList do
			local key = keyList[i]
			if type(key) == 'number' and key > 0 and key - 1 == prev_key then
				prev_key = key
				in_seq = true
			else
				in_seq = false
			end

			local value = dataTable[key]
			if type(value) == 'table' then
				if tableRef[value] == nil then -- prevent reference loops
					tableRef[value] = true

					local has_items = false
					for k,v in pairs(value) do
						if isPrimitiveType[type(k)] and (isPrimitiveType[type(v)] or type(v) == 'table') then
							has_items = true
							break
						end
					end

					if has_items then -- table contains values
						if isPrimitiveArray(value) then -- collapse primitive arrays
							output = output .. indentStr .. formatKey(key,in_seq) .. "{"
							local n = #value
							for i=1,n do
								output = output .. formatValue(value[i])
								if i < n then
									output = output .. ", "
								end
							end
							output = output .. "};\n"
						else -- table is not primitive array
							output = output
							.. indentStr .. formatKey(key,in_seq) .. "{\n"
							.. traverseTable(value,tableRef,indent+1)
							.. indentStr .. "};\n"
						end
					else -- table is empty
						output = output .. indentStr .. formatKey(key,in_seq) .. "{};\n"
					end

					tableRef[value] = nil
				end
			elseif isPrimitiveType[type(value)] then
				output = output .. indentStr .. formatKey(key,in_seq) .. formatValue(value) .. ";\n"
			end
		end
		return output
	end

	function PrettyPrint(dataTable)
		return "{\n" .. traverseTable(dataTable,{[dataTable]=true},1) .. "}"
	end
end

return PrettyPrint