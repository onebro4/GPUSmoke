#ifndef __SIMULATION
#define __SIMULATION

#include "Libraries.h"



// Runs a single iteration of the simulation
void simulate_fluid(fluid_state& state, std::vector<OBJECT>& object_list, int ACCURACY_STEPS = 35)
{
    float AMBIENT_TEMPERATURE = 0.0f;//0.0f
    float BUOYANCY = 1.0f; //1.0f

    float measured_time = 0.0f;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    const int s = 8;//8
    dim3 block(s, s, s);
    dim3 grid((state.dim.x + s - 1) / s,
        (state.dim.y + s - 1) / s,
        (state.dim.z + s - 1) / s);

    cudaEventRecord(start, 0);

    advection << <grid, block >> > (
        state.velocity->readTarget(),
        state.velocity->readTarget(),
        state.velocity->writeTarget(),
        state.dim, state.time_step, 1.0);//1.0
    state.velocity->swap();

    advection << <grid, block >> > (
        state.velocity->readTarget(),
        state.temperature->readTarget(),
        state.temperature->writeTarget(),
        state.dim, state.time_step, 0.998);//0.998
    state.temperature->swap();

    advection << <grid, block >> > (  //zanikanie
        state.velocity->readTarget(),
        state.density->readTarget(),
        state.density->writeTarget(),
        state.dim, state.time_step, 0.995);//0.9999
    state.density->swap();

    buoyancy << <grid, block >> > (
        state.velocity->readTarget(),
        state.temperature->readTarget(),
        state.density->readTarget(),
        state.velocity->writeTarget(),
        AMBIENT_TEMPERATURE, state.time_step, 1.0f, state.f_weight, state.dim);
    state.velocity->swap();

    float3 location = state.impulseLoc;


    /////Z - glebia
    /////X - lewo prawo
    /////Y - gora dol
    float MOVEMENT_SIZE = 9.0;//90.0
    float MOVEMENT_SPEED = 10.0;
    bool MOVEMENT = true;
    if (MOVEMENT) {
        location.x += MOVEMENT_SIZE * 2.0 * sinf(-0.04f * MOVEMENT_SPEED * float(state.step));//-0.003f
        //location.y += cosf(-0.03f * float(state.step));//-0.003f
        location.z += MOVEMENT_SIZE * cosf(-0.02f * MOVEMENT_SPEED * float(state.step));//-0.003f
    }

    for (int i = 0; i < object_list.size(); i++) {
        OBJECT current = object_list[i];
        if (current.get_type() == "smoke")
            object_list.erase(object_list.begin() + i); //remove emmiter from the list

        float3 SIZEE = make_float3(current.get_size(), current.get_size(), current.get_size());

        wavey_impulse << < grid, block >> > (
            state.temperature->readTarget(),
            current.get_location(), SIZEE,
            state.impulseTemp, current.get_initial_velocity(), current.get_velocity_frequence(),
            state.dim
            );
        wavey_impulse << < grid, block >> > (
            state.density->readTarget(),
            current.get_location(), SIZEE,
            state.impulseDensity, current.get_initial_velocity() * (1.0 / current.get_initial_velocity()), current.get_velocity_frequence(),
            state.dim
            );
    }



    divergence << <grid, block >> > (
        state.velocity->readTarget(),
        state.diverge, state.dim, 0.5);//0.5

// clear pressure
    impulse << <grid, block >> > (
        state.pressure->readTarget(),
        make_float3(0.0), 1000000.0f,
        0.0f, state.dim);

    for (int i = 0; i < ACCURACY_STEPS; i++)
    {
        pressure_solve << <grid, block >> > (
            state.diverge,
            state.pressure->readTarget(),
            state.pressure->writeTarget(),
            state.dim, -1.0);
        state.pressure->swap();
    }

    subtract_pressure << <grid, block >> > (
        state.velocity->readTarget(),
        state.velocity->writeTarget(),
        state.pressure->readTarget(),
        state.dim, 1.0);
    state.velocity->swap();

    cudaEventRecord(stop, 0);
    cudaThreadSynchronize();
    cudaEventElapsedTime(&measured_time, start, stop);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    std::cout << "Simulation Time: " << measured_time << "  ||";
}





// Runs a single iteration of the simulation
void simulate_fluid(fluid_state_huge& state, std::vector<OBJECT>& object_list, int ACCURACY_STEPS = 35)
{
    float AMBIENT_TEMPERATURE = 0.0f;//0.0f
    float BUOYANCY = 1.0f; //1.0f

    float measured_time = 0.0f;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    const int s = 8;//8
    dim3 block(s, s, s);
    dim3 grid((state.dim.x + s - 1) / s,
        (state.dim.y + s - 1) / s,
        (state.dim.z + s - 1) / s);

    cudaEventRecord(start, 0);

    advection << <grid, block >> > (
        state.velocity->readTarget(),
        state.velocity->readTarget(),
        state.velocity->writeTarget(),
        state.dim, state.time_step, 1.0);//1.0
    state.velocity->swap();

    advection << <grid, block >> > (
        state.velocity->readTarget(),
        state.temperature->readTarget(),
        state.temperature->writeTarget(),
        state.dim, state.time_step, 0.998);//0.998
    state.temperature->swap();

    advection << <grid, block >> > (  //zanikanie
        state.velocity->readTarget(),
        state.density->readTarget(),
        state.density->writeTarget(),
        state.dim, state.time_step, 0.995);//0.9999
    state.density->swap();

    buoyancy << <grid, block >> > (
        state.velocity->readTarget(),
        state.temperature->readTarget(),
        state.density->readTarget(),
        state.velocity->writeTarget(),
        AMBIENT_TEMPERATURE, state.time_step, 1.0f, state.f_weight, state.dim);
    state.velocity->swap();

    float3 location = state.impulseLoc;


    /////Z - glebia
    /////X - lewo prawo
    /////Y - gora dol
    float MOVEMENT_SIZE = 9.0;//90.0
    float MOVEMENT_SPEED = 10.0;
    bool MOVEMENT = true;
    if (MOVEMENT) {
        location.x += MOVEMENT_SIZE * 2.0 * sinf(-0.04f * MOVEMENT_SPEED * float(state.step));//-0.003f
        //location.y += cosf(-0.03f * float(state.step));//-0.003f
        location.z += MOVEMENT_SIZE * cosf(-0.02f * MOVEMENT_SPEED * float(state.step));//-0.003f
    }

    for (int i = 0; i < object_list.size(); i++) {
        OBJECT current = object_list[i];
        if (current.get_type() == "smoke")
            object_list.erase(object_list.begin() + i); //remove emmiter from the list

        float3 SIZEE = make_float3(current.get_size(), current.get_size(), current.get_size());

        wavey_impulse << < grid, block >> > (
            state.temperature->readTarget(),
            current.get_location(), SIZEE,
            state.impulseTemp, current.get_initial_velocity(), current.get_velocity_frequence(),
            state.dim
            );
        wavey_impulse << < grid, block >> > (
            state.density->readTarget(),
            current.get_location(), SIZEE,
            state.impulseDensity, current.get_initial_velocity() * (1.0 / current.get_initial_velocity()), current.get_velocity_frequence(),
            state.dim
            );
    }



    divergence << <grid, block >> > (
        state.velocity->readTarget(),
        state.diverge, state.dim, 0.5);//0.5

// clear pressure
    impulse << <grid, block >> > (
        state.pressure->readTarget(),
        make_float3(0.0), 1000000.0f,
        0.0f, state.dim);

    for (int i = 0; i < ACCURACY_STEPS; i++)
    {
        pressure_solve << <grid, block >> > (
            state.diverge,
            state.pressure->readTarget(),
            state.pressure->writeTarget(),
            state.dim, -1.0);
        state.pressure->swap();
    }

    subtract_pressure << <grid, block >> > (
        state.velocity->readTarget(),
        state.velocity->writeTarget(),
        state.pressure->readTarget(),
        state.dim, 1.0);
    state.velocity->swap();

    cudaEventRecord(stop, 0);
    cudaThreadSynchronize();
    cudaEventElapsedTime(&measured_time, start, stop);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    std::cout << "Simulation Time: " << measured_time << "  ||";
}

#endif