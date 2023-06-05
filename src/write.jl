
"""
Writes out the alpha vectors in the `.alpha` file format
"""
function Base.write(io::IO, alphas::POMDPAlphas)

	vector_length = size(alphas.alpha_vectors, 1)

	for i in 1 : length(alphas.alpha_actions)
		println(io, alphas.alpha_actions[i])

		for j in 1 : vector_length
			@printf(io, "%.25f", alphas.alpha_vectors[j,i])
			if j != vector_length
				print(io, " ")
			else
				print(io, "\n")
			end
		end

		println(io, "")
	end
end

"""
Write out a `.pomdp` file using the POMDPs.jl interface
Specification: http://cs.brown.edu/research/ai/pomdp/examples/pomdp-file-spec.html
"""
function Base.write(io::IO, pomdp::POMDP; pretty = false)

    ss = states(pomdp)
    as = actions(pomdp)
    os = observations(pomdp)
	println(io, "discount: ", discount(pomdp))
	println(io, "values: reward") # NOTE(tim): POMDPs.jl assumes rewards rather than costs

	n_states = length(ss)
	if pretty && n_states < 20
    	println(io, "states: ", join([string(s) for s=ss], " "))
	else
    	println(io, "states: ", length(ss))
	end

	n_actions = length(as)
	if pretty && n_actions < 20
    	println(io, "actions: ", join([string(a) for a=as], " "))
	else
    	println(io, "actions: ", length(as))
	end

	n_observations = length(os)
	if pretty && n_observations < 20
    	println(io, "observations: ", join([string(o) for o=os], " "))
	else
    	println(io, "observations: ", length(os))
	end

	println(io)

	if pretty
		pretty_print(io, pomdp)
	else
		normal_print(io, pomdp)
	end
end

function normal_print(io::IO, pomdp::POMDP)
	# --------------------------------------------------------------------------
	# TRANSITION
	#
	# T: <action>
	# %f %f ... %f
	# %f %f ... %f
	# ...
	# %f %f ... %f
	#
	# each row corresponds to one of the start states and
	# each column specifies one of the ending states

    pomdp_states = ordered_states(pomdp)
    pomdp_actions = ordered_actions(pomdp)

	for (action_index, a) in enumerate(pomdp_actions)
		println(io, "T:", action_index-1)
		for s in pomdp_states
			T = transition(pomdp, s, a)
			for (end_state_index, s2) in enumerate(pomdp_states)
				print(io, pdf(T, s2))
				if end_state_index != length(pomdp_states)
					print(io, " ")
				else
					print(io, "\n")
				end
			end
		end
		print(io, "\n")
	end

	# --------------------------------------------------------------------------
	# OBSERVATION
	#
	# O: <action>
	# %f %f ... %f
	# %f %f ... %f
	# ...
	# %f %f ... %f
	#
	# each row corresponds to one of the states and
	# each column specifies one of the observations

    pomdp_observations = ordered_observations(pomdp)

	for (action_index, a) in enumerate(pomdp_actions)
		println(io, "O:", action_index-1)
		for (state_index, s) in enumerate(pomdp_states)
			O = observation(pomdp, a, s)
			for (obs_index, o) in enumerate(pomdp_observations)
				print(io, pdf(O, o))
				if obs_index != length(pomdp_observations)
					print(io, " ")
				else
					print(io, "\n")
				end
			end
		end
		print(io, "\n")
	end

	# --------------------------------------------------------------------------
	# REWARD
	#
	# R: <action> : <start-state> : <end-state> : <observation> %f
	# where * is used for <end-state> and <observation> to indicate a wildcard
	# that is expanded to all existing entities

	for (action_index, a) in enumerate(pomdp_actions)
		for (start_state_index, s) in enumerate(pomdp_states)
            for (end_state_index, sp) in enumerate(pomdp_states)
                for (obs_index, o) in enumerate(pomdp_observations)
                    r = reward(pomdp, s, a, sp, o)
                    println(io, "R:", action_index-1, ":", start_state_index-1,
                            ":", end_state_index-1, ":", obs_index-1, " ", r)
                end
            end
		end
	end
end

function pretty_print(io::IO, pomdp::POMDP)
	_states       = ordered_states( pomdp)
	_actions      = ordered_actions(pomdp)
	_observations = ordered_observations(pomdp)

	println("# ------------------------------------------------------------------------")
	println("# TRANSITIONS")
	println("T: * : * : * 0.0")
	for action=_actions, state=_states, statep=_states
		T = transition(pomdp, state, action)
		println(io, "T: $(action) : $(state) : $(statep) : $(pdf(T, statep))")
	end
	println(io)

	println("# ------------------------------------------------------------------------")
	println("# OBSERVATIONS")
	println("O: * : * : * 0.0")
	for action=_actions, statep=_states, obs=_observations
		O = observation(pomdp, action, statep)
		println(io, "O: $(action) : $(statep) : $(obs) $(pdf(O, obs))")
	end
	println(io)

	println("# ------------------------------------------------------------------------")
	println("# REWARDS")
	println("R: * : * : * : * 0.0")
	for action=_actions, state=_states, statep=_states, obs=_observations
		r = reward(pomdp, state, action, statep, obs)
		println(io, "R: $(action) : $(state) : $(statep) : $(obs) $(r)")
	end
	println(io)
end